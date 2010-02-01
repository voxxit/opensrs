require 'uri'
require 'net/https'
require 'digest/md5'
require 'openssl'

module OpenSRS
  class Server
    attr_accessor :server, :username, :password, :key

    def initialize(options = {})
      @server   = URI.parse(options[:server] || "https://rr-n1-tor.opensrs.net:55443/")
      @username = options[:username]
      @password = options[:password]
      @key      = options[:key]
    end

    def call(options = {})
      xml = OpenSRS::XML.build({
        :protocol   => "XCP",
        :action     => options[:action],
        :object     => options[:object],
        :attributes => options[:attributes]
      })
      
      response = http.post(server.path, xml, headers(xml))
      parsed_response = OpenSRS::XML.parse(response.body)
      
      return OpenSRS::Response.new(parsed_response)
    end
    
    private
    
    def headers(request)
      headers = {
        "Content-Length"  => request.length.to_s,
        "Content-Type"    => "text/xml",
        "X-Username"      => username,
        "X-Signature"     => signature(request)
      }
      
      return headers
    end
    
    def signature(request)
      signature = Digest::MD5.hexdigest(request + key)
      signature = Digest::MD5.hexdigest(signature + key)
      signature
    end
    
    def http
      http = Net::HTTP.new(server.host, server.port)
      http.use_ssl = (server.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http
    end
  end
end