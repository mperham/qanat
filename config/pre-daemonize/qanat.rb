# Qanat core and DSL
require 'qanat'

# Require your message processor classes, referenced below
require 'processors/image_crawler'

Qanat.setup do

# Example: Local beanstalk MQ server
  server :beanstalk do
    host 'localhost'
    port 11300
  end

# Example: Amazon SQS
  # server :sqs do
  #   access_key '25NFSD73ACZA0222PMR2'
  #   secret_key 'FHGkQP3f3d1dDLk4ZbDh5ph2S9JkiSQ2rxyxJZyg'
  # end

# Now define the queues
  queue 'default' do
    workers 2
    processor ImageCrawler
  end

  # queue 'page_indexing' do |q|
  #   worker_count 20
  #   processor PageIndexer
  # end
end