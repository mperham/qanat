module Qanat

  class Server
    attr_accessor :type
    attr_accessor :config

    def initialize(name, &block)
      self.type = name
      self.config = {}
      instance_eval(&block)
    end

    def method_missing(name, *args)
      @config[name.to_sym] = args.first
    end
  end

  class Queue
    attr_accessor :worker_count
    attr_accessor :name
    attr_accessor :processor
    attr_accessor :config

    def initialize(name, &block)
      self.name = name
      self.config = {}
      instance_eval(&block)
    end

    def worker_count(count)
      @worker_count = count
    end

    def processor(proc)
      @processor = proc
    end

    def method_missing(name, *args)
      @config[name.to_sym] = args.first
    end
  end

  def self.server(type, &block)
    @server = Server.new(type, &block)
  end

  def self.queue(name, &block)
    @queues ||= []
    @queues << Queue.new(name, &block)
  end

  def self.configuration
    [@server, @queues]
  end

  def self.setup(&block)
    instance_eval(&block)
  end

  def self.load(config)
    config = config.to_s
    config += '.yml' unless config =~ /\.yml$/

    hash = {}
    path = File.join( DAEMON_ROOT, 'config', config )
    hash.merge!(YAML.load_file( path )) if File.exists?(path)

    path = File.join( ENV['HOME'], ".qanat.#{config}" )
    hash.merge!(YAML.load_file( path )) if File.exists?(path)
    
    raise ArgumentError, "Can't find #{path}" if hash.size == 0

    hash[DAEMON_ENV]
  end
end