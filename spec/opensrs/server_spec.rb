require 'spec_helper'

describe OpenSRS::Server do
  let(:server) { OpenSRS::Server.new }

  describe '#new' do
    it 'allows timeouts to be set' do
      server = OpenSRS::Server.new({ :timeout => 90 })
      server.timeout.should == 90
      server.open_timeout.should be_nil
    end

    it 'allows open timeouts to be set' do
      server = OpenSRS::Server.new({ :timeout => 90, :open_timeout => 10 })
      server.timeout.should eq(90)
      server.open_timeout.should eq(10)
    end

    it 'leaves it up to Net::HTTP if no timeouts given' do
      server.timeout.should be_nil
      server.open_timeout.should be_nil
    end

    it 'allows a logger to be set during initialization' do
      logger = double(:info => '')
      server = OpenSRS::Server.new({ :logger => logger })
      server.logger.should eq(logger)
    end
  end

  describe ".call" do
    let(:response) { double(:body => 'some response') }
    let(:header) { {"some" => "header" } }
    let(:xml) { '<some xml></some xml>' }
    let(:response_xml) { xml }
    let(:xml_processor) { double OpenSRS::XmlProcessor }
    let(:http) { double(Net::HTTP, :use_ssl= => true, :verify_mode= => true)  }

    before :each do
      server.stub(:headers).and_return header
      xml_processor.stub(:build).and_return xml
      xml_processor.stub(:parse).and_return response_xml
      server.stub(:xml_processor).and_return xml_processor
      http.stub(:post).and_return response
      Net::HTTP.stub(:new).and_return http
    end

    it "builds XML request" do
      xml_processor.should_receive(:build).with(:protocol => "XCP", :some => 'option')
      server.call(:some => 'option')
    end

    it "posts to given path" do
      server.server = URI.parse 'http://with-path.com/endpoint'
      http.should_receive(:post).with('/endpoint', xml, header).and_return double.as_null_object
      server.call
    end

    it "parses the response" do
      xml_processor.should_receive(:parse).with(response.body)
      server.call(:some => 'option')
    end

    it "posts to root path" do
      server.server = URI.parse 'http://root-path.com/'
      http.should_receive(:post).with('/', xml, header).and_return double.as_null_object
      server.call
    end

    it "defaults path to '/'" do
      server.server = URI.parse 'http://no-path.com'
      http.should_receive(:post).with('/', xml, header).and_return double.as_null_object
      server.call
    end

    it 'allows overriding of default (Net:HTTP) timeouts' do
      server.timeout = 90

      http.should_receive(:open_timeout=).with(90)
      http.should_receive(:read_timeout=).with(90)

      server.call( { :some => 'data' } )
    end

    it 'allows overriding of default (Net:HTTP) timeouts' do
      server.timeout = 180
      server.open_timeout = 30

      http.should_receive(:read_timeout=).with(180)
      http.should_receive(:open_timeout=).with(180)
      http.should_receive(:open_timeout=).with(30)

      server.call( { :some => 'data' } )
    end

    it 're-raises Net:HTTP timeouts' do
      http.should_receive(:post).and_raise err = Timeout::Error.new('test')
      expect { server.call }.to raise_exception OpenSRS::TimeoutError
    end

    describe "logger is present" do
      let(:logger) { OpenSRS::TestLogger.new }
      before :each do
        server.logger = logger
      end

      it "should log the request and the response" do
        xml_processor.should_receive(:build).with(:protocol => "XCP", :some => 'option')
        server.call(:some => 'option')
        logger.messages.length.should eq(2)
        logger.messages.first.should match(/\[OpenSRS\] Request XML/)
        logger.messages.last.should match(/\[OpenSRS\] Response XML/)
      end

    end
  end

  describe "#test xml processor" do
    context "on class initialization" do
      it { server.xml_processor.should eql(OpenSRS::XmlProcessor::Libxml) }
    end

    context "on changing xml processor" do
      before(:each) do
        OpenSRS::Server.xml_processor = :nokogiri
      end

      it { server.xml_processor.should eql(OpenSRS::XmlProcessor::Nokogiri) }
    end
  end
end
