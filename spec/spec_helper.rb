require 'date'

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'opensrs'

class OrderedHash < Hash
end

module OpenSRS
  class TestLogger
    attr_reader :messages

    def initialize
      @messages = []
    end

    def info(message)
      messages << message
    end
  end
end
