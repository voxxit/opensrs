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
      build_element(:dt_array, data, container)
    end

    def self.encode_dt_assoc(data, container)
      build_element(:dt_assoc, data, container)
    end

    def self.build_element(type, data, container)
      element = new_element(type, container)

      # if array, item = the item
      # if hash, item will be array of the key & value
      data.each_with_index do |item, index|
        item_node = new_element(:item, container)
        item_node["key"] = item.is_a?(Array) ? item[0].to_s : index.to_s

        value = item.is_a?(Array) ? item[1] : item

        item_node << encode_data(value, item_node)
        element << item_node
      end

      element
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
