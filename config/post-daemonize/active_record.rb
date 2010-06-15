#require 'yaml'
#require 'erb'
# require 'active_record'
# 
# RAILS_ENV=DaemonKit.configuration.environment
# 
# ActiveRecord::Base.configurations = YAML::load(ERB.new(File.read(File.join(DAEMON_ROOT, 'config', 'database.yml'))).result)
# ActiveRecord::Base.default_timezone = :utc
# ActiveRecord::Base.logger = DaemonKit.logger
# ActiveRecord::Base.logger.level = Logger::INFO
# ActiveRecord::Base.time_zone_aware_attributes = true
# Time.zone = 'UTC'
# ActiveRecord::Base.establish_connection