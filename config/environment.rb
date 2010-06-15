# Be sure to restart your daemon when you modify this file

# Uncomment below to force your daemon into production mode
#ENV['DAEMON_ENV'] ||= 'production'

require 'fileutils'
FileUtils.mkdir_p(File.dirname(__FILE__) + '/../log')

# Boot up
require File.join(File.dirname(__FILE__), 'boot')

DaemonKit::Initializer.run do |config|
  # The name of the daemon as reported by process monitoring tools
  config.daemon_name = 'qanat'

  # Force the daemon to be killed after X seconds from asking it to
  config.force_kill_wait = 30

  # Log backraces when a thread/daemon dies (Recommended)
  config.backtraces = true

  # Configure the safety net (see DaemonKit::Safety)
  # config.safety_net.handler = :mail # (or :hoptoad )
  # config.safety_net.mail.host = 'localhost'
end

require 'qanat'

# Qanat.setup do
#
## Example: Local beanstalk MQ server
#   server :beanstalk do
#     host 'localhost'
#     port 11300
#   end
#
## Example: Amazon SQS
#   server :sqs do
#     access_key '25NFSD73ACZA0222PMR2'
#     secret_key 'FHGkQP3f3d1dDLk4ZbDh5ph2S9JkiSQ2rxyxJZyg'
#   end
#
## Now define the queues
#   queue 'image_crawling' do
#     worker_count 10
#     processor ImageCrawler
#   end
#    
#   queue 'page_indexing' do |q|
#     worker_count 20
#     processor PageIndexer
#   end
# end
# 
# p Qanat.configuration