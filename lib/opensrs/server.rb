require "uri"
require "net/https"
require "digest/md5"
require "openssl"

module OpenSRS
  class BadResponse < StandardError; end

  class Server
    attr_accessor :server, :username, :password, :key

    def initialize(options = {})
      @server   = URI.parse(options[:server] || "https://rr-n1-tor.opensrs.net:55443/")
      @username = options[:username]
      @password = options[:password]
      @key      = options[:key]
    end

    def call(options = {})
      xml = xml_processor.build({ :protocol => "XCP" }.merge!(options))
      response = http.post(server_path, xml, headers(xml))
      parsed_response = xml_processor.parse(response.body)

      return OpenSRS::Response.new(parsed_response, xml, response.body)
    rescue Net::HTTPBadResponse
      raise OpenSRS::BadResponse, "Received a bad response from OpenSRS. Please check that your IP address is added to the whitelist, and try again."
    end

    def xml_processor
      @@xml_processor
    end

    def self.xml_processor=(name)
      require File.dirname(__FILE__) + "/xml_processor/#{name.to_s.downcase}"
      @@xml_processor = OpenSRS::XmlProcessor.const_get("#{name.to_s.capitalize}")
    end

    OpenSRS::Server.xml_processor = :libxml

    private

    def headers(request)
      { "Content-Length"  => request.length.to_s,
        "Content-Type"    => "text/xml",
        "X-Username"      => username,
        "X-Signature"     => signature(request)
      }
    end

    def signature(request)
      signature = Digest::MD5.hexdigest(request + key)
      signature = Digest::MD5.hexdigest(signature + key)
      signature
    end

    def http
      http = Net::HTTP.new(server.host, server.port)
      http.use_ssl = (server.scheme == "https")
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http
    end

    def server_path
      server.path.empty? ? '/' : server.path
    end
  end
end
