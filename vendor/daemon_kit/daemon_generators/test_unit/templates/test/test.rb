require File.dirname(__FILE__) + '/test_helper.rb'

class Test<%= module_name %> < Test::Unit::TestCase

  def test_missing
    assert false, "daemons should be tested"
  end
end

