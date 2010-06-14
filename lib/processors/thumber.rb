
GLOB='/Users/mike/junk/test_images/*.jpg'

require 'evented_magick'

a = Time.now
files = Dir[GLOB]
files.each do |filename|
  image = EventedMagick::Image.new(filename)
  image['dimensions']
end

puts "Processed #{files.size} in #{Time.now - a} sec"

if defined? Fiber
  require 'fiber'
  require 'eventmachine'
  
  NUM = 5
  items = EM::Queue.new
  total = 0
  process = proc do |filename|
    begin
      Fiber.new do
        image = EventedMagick::Image.new(filename)
        image['dimensions']
        total = total + 1
        items.pop(process)
      end.resume
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace.join("\n")
    end
  end

  EM.run do
    a = Time.now
    files = Dir[GLOB]
    files.each do |filename|
      items.push filename
    end

    NUM.times{ items.pop(process) }
    EM.add_periodic_timer(1) do
      if items.empty?
        puts "Processed #{total} in #{Time.now - a} sec"
        EM.stop
      end
    end
  end

end    