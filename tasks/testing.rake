require 'beanstalk-client'

# Some sample Rake tasks to perform common queue tasks.
namespace :msg do
  task :push do
    beanstalk = Beanstalk::Pool.new(['localhost:11300'])
    10.times do |idx|
      beanstalk.put idx.to_s
    end
  end

  task :clone do
  end
end
