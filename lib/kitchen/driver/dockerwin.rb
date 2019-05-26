require 'kitchen/shell_out'
require 'kitchen/transport/dockercli'

module Kitchen
  module Driver
    #
    # DockerWindows - Windows Containers via Docker
    #
    class Dockerwin < Kitchen::Driver::Base
      default_config(:image) do |_config|
        'mcr.microsoft.com/windows/servercore:ltsc2019'
      end

      def create(state)
        run_command("docker pull #{instance.driver[:image]}") unless config[:skip_pull]
        mount_options = config[:mount_options] || "type=bind,source=\"#{ENV['TEMP']}\",target=\"#{ENV['TEMP']},readonly\""
        container_id = run_command("docker run -idt --mount #{mount_options} --name #{instance.name} #{instance.driver[:image]}").strip
        state[:container_id] = container_id
      end

      def destroy(state)
        return if state[:container_id].nil?
        container_id = state[:container_id]
        info 'Killing container'
        run_command("docker kill #{container_id} > nul")
        info 'Removing container'
        run_command("docker rm #{container_id} > nul")
        state.delete(:container_id)
      end

      # Force the driver to use the Dockercli transport
      def finalize_config!(instance)
        super.tap do
          instance.transport = Kitchen::Transport::Dockercli.new
        end
      end
    end
  end
end
