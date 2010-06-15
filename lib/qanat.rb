module Qanat
  QUEUES = []

  class Queue
    attr_accessor :worker_count
    attr_accessor :name
    attr_accessor :processor

    def initialize(name, &block)
      self.name = name
      yield self
    end
  end

  def self.queue(name, &block)
    QUEUES << Queue.new(name, &block)
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
    