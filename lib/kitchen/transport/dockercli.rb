require 'kitchen/shell_out'
require 'kitchen/transport/base'
require "kitchen/version"
require "securerandom"
require "base64"

module Kitchen
  module Transport
    # Driver for Docker on Windows.
    #
    # @author Stuart Preston <stuart@chef.io>
    class Dockercli < Kitchen::Transport::Base
      kitchen_transport_api_version 2
      plugin_version Kitchen::VERSION
      
      def connection(state, &block)
        options = config.to_hash.merge(state)
        Kitchen::Transport::Dockercli::Connection.new(options, &block)
      end
      
      class Connection < Kitchen::Transport::Base::Connection
        include ShellOut

        def execute(command)
          return if command.nil?
          tempfile = "#{SecureRandom.hex(4)}.ps1"
          tempfile_path = File.join(ENV['TEMP'], tempfile)
          translated_path = translate_path(tempfile_path)          
          begin
            File.open((tempfile_path), 'w') { |file| file.write(command) }
            dockered_command = "docker exec #{options[:container_id]} powershell.exe -noprofile -noninteractive -executionpolicy unrestricted -file #{translated_path}"
            run_command(dockered_command)
          ensure
            File.unlink(tempfile_path)
          end
        end

        def upload(locals, remote)
          powershell_commands = Array.new 
          Array(locals).each do |local|
           powershell_commands << "copy-item #{translate_path(local)} #{remote} -force -recurse;"
          end
          execute(powershell_commands.join)
        end

        def download(remotes, local)
          powershell_commands = Array.new 
          Array(remotes).each do |remote|
           powershell_commands << "copy-item #{remote} #{translate_path(local)} -force -recurse;"
          end
          execute(powershell_commands.join)
        end

        def login_command
          LoginCommand.new("docker exec -it #{options[:container_id]} powershell.exe -noprofile -executionpolicy unresticted", nil)
        end

        private

        def translate_path(path)
          path.downcase.gsub("c:", "\/mnt\/c")
        end
      end
    end
  end
end 