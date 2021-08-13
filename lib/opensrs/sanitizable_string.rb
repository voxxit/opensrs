require 'delegate'

module OpenSRS
  # SanitizableString
  class SanitizableString < SimpleDelegator
    @enable_sanitization = false

    class << self
      attr_accessor :enable_sanitization
    end

    def initialize(original_string, sanitized_string)
      super(original_string)
      @sanitized_string = sanitized_string
    end

    def sanitized
      self.class.enable_sanitization ? @sanitized_string : self
    end
  end
end
