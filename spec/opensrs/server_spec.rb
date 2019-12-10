describe OpenSRS::Server do
  before(:each) do
    OpenSRS::Server.xml_processor = :libxml
  end

  let(:server) { OpenSRS::Server.new }

  describe '#new' do
    it 'allows timeouts to be set' do
      server = OpenSRS::Server.new({ :timeout => 90 })

      expect(server.timeout).to be(90)
      expect(server.open_timeout).to be_nil
    end

    it 'allows open timeouts to be set' do
      server = OpenSRS::Server.new({ :timeout => 90, :open_timeout => 10 })

      expect(server.timeout).to be(90)
      expect(server.open_timeout).to be(10)
    end

    it 'leaves it up to Net::HTTP if no timeouts given' do
      expect(server.timeout).to be_nil
      expect(server.open_timeout).to be_nil
    end

    it 'allows a logger to be set during initialization' do
      logger = double(:info => '')
      server = OpenSRS::Server.new({ :logger => logger })

      expect(server.logger).to be(logger)
    end
  end

  describe ".call" do
    let(:response) { double(:body => 'some response') }
    let(:header) { {"some" => "header" } }
    let(:wrapped_xml) do
      OpenSRS::SanitizableString.new(
        request_xml, "<sanitized xml></sanitized xml>"
      )
    end
    let(:xml) { "<some xml></some xml>" }
    let(:request_xml) { "<some request xml></some request xml>" }
    let(:response_xml) { xml }
    let(:xml_processor) { double OpenSRS::XmlProcessor }
    let(:http) { double(Net::HTTP, :use_ssl= => true, :verify_mode= => true)  }

    before :each do
      allow(server).to receive(:headers).and_return header
      allow(xml_processor).to receive(:build).and_return wrapped_xml
      allow(xml_processor).to receive(:parse).and_return response_xml
      allow(server).to receive(:xml_processor).and_return xml_processor
      allow(http).to receive(:post).and_return response
      allow(Net::HTTP).to receive(:new).and_return http
    end

    it "builds XML request" do
      expect(xml_processor).to receive(:build).
        with(protocol: "XCP", some: "option")
      server.call(some: "option")
    end

    it "posts to given path" do
      server.server = URI.parse "http://with-path.com/endpoint"
      expect(http).to receive(:post).with("/endpoint", request_xml, header).
        and_return double.as_null_object
      server.call
    end

    it "parses the response" do
      expect(xml_processor).to receive(:parse).with(response.body)
      server.call(:some => 'option')
    end

    it "posts to root path" do
      server.server = URI.parse "http://root-path.com/"
      expect(http).to receive(:post).with("/", request_xml, header).
        and_return double.as_null_object
      server.call
    end

    it "defaults path to '/'" do
      server.server = URI.parse "http://no-path.com"
      expect(http).to receive(:post).with("/", request_xml, header).
        and_return double.as_null_object
      server.call
    end

    it 'allows overriding of default (Net:HTTP) timeouts' do
      server.timeout = 90

      expect(http).to receive(:open_timeout=).with(90)
      expect(http).to receive(:read_timeout=).with(90)

      server.call( { :some => 'data' } )
    end

    it 'allows overriding of default (Net:HTTP) timeouts' do
      server.timeout = 180
      server.open_timeout = 30

      expect(http).to receive(:read_timeout=).with(180)
      expect(http).to receive(:open_timeout=).with(180)
      expect(http).to receive(:open_timeout=).with(30)

      server.call( { :some => 'data' } )
    end

    it 're-raises Net:HTTP timeouts' do
      expect(http).to receive(:post).and_raise Timeout::Error.new("test")
      expect { server.call }.to raise_exception OpenSRS::TimeoutError
    end

    it 'wraps connection errors' do
      expect(http).to receive(:post).and_raise Errno::ECONNREFUSED
      expect { server.call }.to raise_exception OpenSRS::ConnectionError

      expect(http).to receive(:post).and_raise Errno::ECONNRESET
      expect { server.call }.to raise_exception OpenSRS::ConnectionError
    end

    it "returns a response object" do
      result = server.call(some: "option")

      expect(result).to be_a OpenSRS::Response
      expect(result.request_xml).to eql request_xml
      expect(result.response_xml).to eql response.body
      expect(result.response).to eql response_xml
    end

    describe "logger is present" do
      let(:logger) { OpenSRS::TestLogger.new }
      before :each do
        server.logger = logger
      end

      it "should log the request and the response" do
        expect(xml_processor). to receive(:build).
          with(protocol: "XCP", some: "option")
        server.call(some: "option")

        expect(logger.messages.length).to be(2)
        expect(logger.messages.first).to match(/\[OpenSRS\] Request XML/)
        expect(logger.messages.first).to match(/<some request xml>/)
        expect(logger.messages.last).to match(/\[OpenSRS\] Response XML/)
        expect(logger.messages.last).to match(/some response/)
      end
    end

    describe "xml sanitization has been enabled" do
      let(:server) { OpenSRS::Server.new(sanitize_request: true) }

      it "populates the returned request instance with sanitized xml" do
        result = server.call(some: "option")

        expect(result).to be_a OpenSRS::Response
        expect(result.request_xml).to eql wrapped_xml.sanitized
        expect(result.response_xml).to eql response.body
        expect(result.response).to eql response_xml
      end

      describe "logger is present" do
        let(:logger) { OpenSRS::TestLogger.new }
        before :each do
          server.logger = logger
        end

        it "should log the request and the sanitized response" do
          expect(xml_processor). to receive(:build).
            with(protocol: "XCP", some: "option")
          server.call(some: "option")

          expect(logger.messages.length).to be(2)
          expect(logger.messages.first).to match(/\[OpenSRS\] Request XML/)
          expect(logger.messages.first).to match(/<sanitized xml>/)
          expect(logger.messages.last).to match(/\[OpenSRS\] Response XML/)
          expect(logger.messages.last).to match(/some response/)
        end
      end
    end
  end

  describe "#test xml processor" do
    context "on changing xml processor" do
      before(:each) do
        OpenSRS::Server.xml_processor = :nokogiri
      end

      it { expect(server.xml_processor).to eql(OpenSRS::XmlProcessor::Nokogiri) }
    end
  end
end
