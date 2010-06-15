require 'fiber'
require 'time'

class Fiber
  def self.sleep(sec)
    f = Fiber.current
    EM.add_timer(sec) do
      f.resume
    end
    Fiber.yield
  end
end