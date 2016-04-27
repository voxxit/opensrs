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
      unless success?
        msg  = @response["response_text"]
        code = @response["response_code"]

        return msg && code ? "#{msg} (Code #{code})" : "Unknown error"
      end
    end

    # If 'is_success' is returned, the API is letting us know that they
    # will explicitly tell us whether something has succeeded or not.
    # Otherwise, just assume it is successful.
    def success?
      @response["is_success"] && @response["is_success"] == "1" ? true : false
    end
  end
end
