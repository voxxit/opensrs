module OpenSRS

  class XmlProcessor

    # Encodes individual elements, and their child elements, for the root XML document.
    def self.encode_data(data, container = nil)
      case data.class.to_s
      when "Array" then return encode_dt_array(data, container)
      when "Hash"  then return encode_dt_assoc(data, container)
      when "String", "Numeric", "Date", "Time", "Symbol", "NilClass"
        return data.to_s
      else
        return data.inspect
      end

      return nil
    end

    # Parses the main data block from OpenSRS and discards
    # the rest of the response.
    def self.parse(response)
      data_block = data_block_element(response)

      raise ArgumentError.new("No data found in document") if !data_block

      return decode_data(data_block)
    end

  end

end