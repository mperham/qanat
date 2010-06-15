require 'em-jack'

module Qanat
  class Beanstalk
    def initialize(config, queue)
      @server = EMJack::Connection.new(config)
      @queue = queue
      @timeout = queue.config[:timeout] || config[:timeout] || 5
    end

    def process_loop
      @processor ||= queue.processor.new
      while true
        job = @server.reserve # ignore timeout for now, blocking should be ok
        @processor.process(job)
        job.delete
      end
    end
  end
end