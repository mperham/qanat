require 'em-jack'

module Qanat
  class Beanstalkd
    def initialize(config, queue_config)
      @server = EMJack::Connection.new(config)
      @timeout = queue_config[:timeout] || config[:timeout] || 5
    end
    
    def process_loop
      job = @server.reserve # ignore timeout for now, blocking should be ok
      yield job
      job.delete
    end
  end
end