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

    def start(queue)
      klass.new(config, queue)
    end

    private

    def klass
      @klass ||= begin
        require "drivers/#{type}"
        constantize("Qanat::#{camelize(type)}")
      end
    end

    def camelize(str)
      str.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    end

    def constantize(camel_cased_word)
      names = camel_cased_word.split('::')
      names.shift if names.empty? || names.first.empty?

      constant = Object
      names.each do |name|
        constant = constant.const_get(name, false) || constant.const_missing(name)
      end
      constant
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