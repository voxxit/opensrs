require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'opensrs/xml_processor.rb'
require 'opensrs/xml_processor/libxml.rb'
require 'opensrs/xml_processor/nokogiri.rb'
require 'opensrs/server.rb'
require 'opensrs/version.rb'
require 'opensrs/response.rb'

class OpenSRS::TestLogger
  attr_reader :messages
  def initialize
    @messages = []
  end

  def info(message)
    messages << message
  end
end
