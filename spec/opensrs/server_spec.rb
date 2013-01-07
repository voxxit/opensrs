require 'spec_helper'

describe OpenSRS::Server do
  let(:server) { OpenSRS::Server.new }

  describe ".call" do
    let(:response) { double(:body => 'some response') }
    let(:header) { {"some" => "header" } }
    let(:xml) { '<some xml></some xml>' }
    let(:response_xml) { xml }
    let(:xml_processor) { double OpenSRS::XmlProcessor }
    let(:http) { double Net::HTTP }

    before :each do
      server.stub(:headers).and_return header
      xml_processor.stub(:build).and_return xml
      xml_processor.stub(:parse).and_return response_xml
      server.stub(:xml_processor).and_return xml_processor
      http.stub(:post).and_return response
      server.stub(:http).and_return http
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
