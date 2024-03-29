require 'uri'
require 'net/https'
require 'digest/md5'
require 'openssl'

module OpenSRS
  class OpenSRSError < StandardError; end

  class BadResponse < OpenSRSError; end

  class ConnectionError < OpenSRSError; end

  class TimeoutError < ConnectionError; end

  # Server
  class Server
    attr_accessor :server, :username, :password, :key, :timeout, :open_timeout, :logger, :proxy

    def initialize(options = {})
      @server   = URI.parse(options[:server] || 'https://rr-n1-tor.opensrs.net:55443/')
      @username = options[:username]
      @password = options[:password]
      @key      = options[:key]
      @timeout  = options[:timeout]
      @open_timeout = options[:open_timeout]
      @logger   = options[:logger]
      @proxy    = URI.parse(options[:proxy]) if options[:proxy]
      @sanitize_request = options[:sanitize_request]

      OpenSRS::SanitizableString.enable_sanitization = @sanitize_request
    end

    def call(data = {})
      xml = xml_processor.build({ protocol: 'XCP' }.merge!(data))
      log('Request', xml.sanitized, data)

      begin
        response = http.post(server_path, xml, headers(xml))
        log('Response', response.body, data)
      rescue Net::HTTPBadResponse
        raise OpenSRS::BadResponse,
              'Received a bad response from OpenSRS. Please check that your IP address is added to the whitelist, and try again.'
      end

      parsed_response = xml_processor.parse(response.body)
      OpenSRS::Response.new(parsed_response, xml.sanitized, response.body)
    rescue Timeout::Error => e
      raise OpenSRS::TimeoutError, e
    rescue Errno::ECONNRESET, Errno::ECONNREFUSED => e
      raise OpenSRS::ConnectionError, e
    end

    def xml_processor
      @@xml_processor
    end

    def self.xml_processor=(name)
      require "opensrs/xml_processor/#{name.to_s.downcase}"
      @@xml_processor = OpenSRS::XmlProcessor.const_get(name.to_s.capitalize.to_s)
    end

    private

    def headers(request)
      {
        'Content-Length' => request.length.to_s,
        'Content-Type' => 'text/xml',
        'X-Username' => username,
        'X-Signature' => signature(request)
      }
    end

    def signature(request)
      Digest::MD5.hexdigest(Digest::MD5.hexdigest(request + key) + key)
    end

    def http
      http = if @proxy
               Net::HTTP.new(server.host, server.port, @proxy.host, @proxy.port, @proxy.user, @proxy.password)
             else
               Net::HTTP.new(server.host, server.port)
             end

      http.use_ssl = (server.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.read_timeout = http.open_timeout = @timeout if @timeout
      http.open_timeout = @open_timeout                if @open_timeout
      http
    end

    def log(type, data, options = {})
      return unless logger

      message = "[OpenSRS] #{type} XML"
      message = "#{message} for #{options[:object]} #{options[:action]}" if options[:object] && options[:action]

      line = [message, data].join("\n")
      logger.info(line)
    end

    def server_path
      server.path.empty? ? '/' : server.path
    end
  end
end
