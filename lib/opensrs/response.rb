module OpenSRS
  class Response
    attr_accessor :response, :success
    
    def initialize(response)
      @response = response
      @success = success?
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