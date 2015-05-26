require 'date'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'opensrs'

class OrderedHash < Hash
end

class OpenSRS::TestLogger
  attr_reader :messages

  def initialize
    @messages = []
  end

  def info(message)
    messages << message
  end
end
