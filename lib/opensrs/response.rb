module OpenSRS
  class Response
    attr_reader :request_xml, :response_xml
    attr_accessor :response, :success
    
    def initialize(parsed_response, request_xml, response_xml)
      @response     = parsed_response
      @request_xml  = request_xml
      @response_xml = response_xml
      @success      = success?
    end
  
    # We need to return the error message unless the
    # response is successful.
    def errors
      "#{response["response_text"]} (Code #{response["response_code"]})" unless success?
    end
  
    def success?
      response["is_success"].to_s == "1"
    end
  end
end