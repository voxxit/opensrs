require 'delegate'

module OpenSRS
  class SanitizableString < SimpleDelegator
    def self.enable_sanitization=(enabled)
      @@enable_sanitization = enabled
    end

    def initialize(original_string, sanitized_string)
      super(original_string)
      @sanitized_string = sanitized_string
    end

    def sanitized
      @@enable_sanitization ? @sanitized_string : self
    end
  end
end
