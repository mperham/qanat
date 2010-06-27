require 'sqs'

module Qanat
  class Sqs
    def initialize(config, queue)
      @server = SQS::Queue.new(queue.name, config)
      @queue = queue
    end

    def process_loop
      @processor ||= @queue.processor_class.new
      while true
        @server.process_msg do |job|
          @processor.process(job)
        end
      end
    end
  end
end