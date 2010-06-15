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

module EMJack
  class Connection

    def fiber!
      eigen = (class << self
       self
      end)
      eigen.instance_eval do
        %w(use reserve ignore watch peek stats list delete touch bury kick pause release put).each do |meth|
          alias_method :"a#{meth}", meth.to_sym
          define_method(meth.to_sym) do |*args|
            fib = Fiber.current
            ameth = :"a#{meth}"
            proc = lambda { |*result| fib.resume(*result) }
            send(ameth, *args, &proc)
            Fiber.yield
          end
        end
      end
    end

  end
end