require "nokogiri"

module OpenSRS
  class Nokogiri

    def self.build(data)
      builder = ::Nokogiri::XML::Builder.new

      envelope   = ::Nokogiri::XML::Node.new("OPS_envelope", builder.doc)
      header     = ::Nokogiri::XML::Node.new("header", builder.doc)
      version    = ::Nokogiri::XML::Node.new("version", builder.doc)
      body       = ::Nokogiri::XML::Node.new("body", builder.doc)
      data_block = ::Nokogiri::XML::Node.new("data_block", builder.doc)
      other_data = encode_data(data, builder.doc)
      builder.doc << envelope << header << version << '0.9'
      envelope << body << data_block << other_data
      return builder.to_xml
    end

    # Parses the main data block from OpenSRS and discards
    # the rest of the response.
    def self.parse(response)
      doc = ::Nokogiri::XML(response)
      data_block = doc.xpath('//OPS_envelope/body/data_block/*')
      raise ArgumentError.new("No data found in document") if !data_block
      return decode_data(data_block)
    end

    protected

    # Recursively decodes individual data elements from OpenSRS
    # server response.
    def self.decode_data(data)
      data.each do |element|
        case element.name
        when "dt_array"
          arr = []

          element.children.each do |item|
            next if item.content.strip.empty?
            arr[item.attributes["key"].value.to_i] = decode_data(item.children)
          end

          return arr
        when "dt_assoc"
          hash = {}

          element.children.each do |item|
            next if item.content.strip.empty?
            hash[item.attributes["key"].value] = decode_data(item.children)
          end

          return hash
        when "text", "item", "dt_scalar"
          next if element.content.strip.empty?
          return element.content.strip
        end
      end
    end

    # Encodes individual elements, and their child elements, for the root
    # XML document.
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

    def self.encode_dt_array(data, container)
      dt_array = ::Nokogiri::XML::Node.new("dt_array", container)

      data.each_with_index do |item, index|
        item_node = ::Nokogiri::XML::Node.new("item", container)
        item_node["key"] = index.to_s
        item_node << encode_data(item, item_node)

        dt_array << item_node
      end

      return dt_array
    end

    def self.encode_dt_assoc(data, container)
      dt_assoc = ::Nokogiri::XML::Node.new("dt_assoc", container)

      data.each do |key, value|
        item_node =::Nokogiri::XML::Node.new("item", container)
        item_node["key"] = key.to_s
        item_node << encode_data(value, item_node)

        dt_assoc << item_node
      end

      return dt_assoc
    end
  end
end
