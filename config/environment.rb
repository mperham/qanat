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
#   server :beanstalkd do
#     host 'localhost'
#     port 11300
#   end
# 
#   queue 'image_crawling' do
#     worker_count 10
#     processor File
#   end
#   # 
#   # queue 'page_indexing' do |q|
#   #   q.worker_count = 20
#   #   q.processor = PageIndexer
#   # end
# end
# 
# p Qanat.configuration