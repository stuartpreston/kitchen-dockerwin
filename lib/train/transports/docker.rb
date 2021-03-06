# encoding: utf-8
#
# Author:: Dominik Richter
# Author:: Christoph Hartmann

require 'docker'

module Train::Transports
  class Docker < Train.plugin(1)
    name 'docker'

    include_options Train::Extras::CommandWrapper
    option :host, required: true

    def connection(state = {}, &block)
      opts = merge_options(options, state || {})
      validate_options(opts)

      if @connection && @connection_options == opts
        reuse_connection(&block)
      else
        create_new_connection(opts, &block)
      end
    end

    private

    # Creates a new Docker connection instance and save it for potential future
    # reuse.
    #
    # @param options [Hash] connection options
    # @return [Docker::Connection] a Docker connection instance
    # @api private
    def create_new_connection(options, &block)
      if @connection
        logger.debug("[Docker] shutting previous connection #{@connection}")
        @connection.close
      end

      @connection_options = options
      @connection = Connection.new(options, &block)
    end

    # Return the last saved Docker connection instance.
    #
    # @return [Docker::Connection] a Docker connection instance
    # @api private
    def reuse_connection
      logger.debug("[Docker] reusing existing connection #{@connection}")
      yield @connection if block_given?
      @connection
    end
  end
end

class Train::Transports::Docker
  class Connection < BaseConnection
    def initialize(conf)
      super(conf)
      @id = options[:host]
      @container = ::Docker::Container.get(@id) ||
                   fail("Can't find Docker container #{@id}")
      @cmd_wrapper = nil
      @cmd_wrapper = CommandWrapper.load(self, @options)
      self
    end

    def close
      # nothing to do at the moment
    end

    def uri
      if @container.nil?
        "docker://#{@id}"
      else
        "docker://#{@container.id}"
      end
    end

    private

    def file_via_connection(path)
      if os.aix?
        Train::File::Remote::Aix.new(self, path)
      elsif os.solaris?
        Train::File::Remote::Unix.new(self, path)
      elsif os.windows?
        Train::File::Remote::Windows.new(self, path)  
      else
        Train::File::Remote::Linux.new(self, path)
      end
    end

    def platform_specific_cmd(cmd)
      return cmd if @container.info.nil?
      if @container.info['Platform'] == 'windows'
        return ['cmd.exe', '/c', cmd]
      else
        return ['/bin/sh', '-c', cmd]
      end
    end

    def run_command_via_connection(cmd, &_data_handler)
      cmd = @cmd_wrapper.run(cmd) unless @cmd_wrapper.nil?
      stdout, stderr, exit_status = @container.exec(platform_specific_cmd(cmd))
      CommandResult.new(stdout.join, stderr.join, exit_status)
    rescue ::Docker::Error::DockerError => _
      raise
    rescue => _
      # @TODO: differentiate any other error
      raise
    end
  end
end
