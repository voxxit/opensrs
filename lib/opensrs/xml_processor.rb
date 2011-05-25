module OpenSRS

  class XmlProcessor

    # Parses the main data block from OpenSRS and discards
    # the rest of the response.
    def self.parse(response)
      data_block = data_block_element(response)

      raise ArgumentError.new("No data found in document") if !data_block

      return decode_data(data_block)
    end

    protected

    # Encodes individual elements, and their child elements, for the root XML document.
    def self.encode_data(data, container = nil)
      case data
      when Array 
        encode_dt_array(data, container)
      when Hash  
        encode_dt_assoc(data, container)
      when String, Numeric, Date, Time, Symbol, NilClass
        data.to_s
      else
        data.inspect
      end
    end

    def self.encode_dt_array(data, container)
      dt_array = new_element(:dt_array, container)

      data.each_with_index do |item, index|
        item_node = new_element(:item, container)
        item_node["key"] = index.to_s
        item_node << encode_data(item, item_node)

        dt_array << item_node
      end

      return dt_array
    end

    def self.encode_dt_assoc(data, container)
      dt_assoc = new_element(:dt_assoc, container)

      data.each do |key, value|
        item_node = new_element(:item, container)
        item_node["key"] = key.to_s
        item_node << encode_data(value, item_node)

        dt_assoc << item_node
      end

      return dt_assoc
    end

    # Recursively decodes individual data elements from OpenSRS
    # server response.
    def self.decode_data(data)
      data.each do |element|
        case element.name
        when "dt_array"
          return decode_dt_array_data(element)
        when "dt_assoc"
          return decode_dt_assoc_data(element)
        when "text", "item", "dt_scalar"
          next if element.content.strip.empty?
          return element.content.strip
        end
      end
    end

  end

end