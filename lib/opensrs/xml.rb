require "libxml"

module OpenSRS
  class XML
    include LibXML::XML
    
    # First, builds REXML elements for the inputted data. Then, it will
    # go ahead and build the entire XML document to send to OpenSRS.
    def self.build(data)
      xml = Document.new
      xml.root = envelope = Node.new("OPS_envelope")

      envelope << header = Node.new("header")
      envelope << body = Node.new("body")
      header   << Node.new("version", "0.9")
      body     << data_block = Node.new("data_block")

      data_block << encode_data(data, data_block)

      return xml.to_s
    end

    # Parses the main data block from OpenSRS and discards
    # the rest of the response.
    def self.parse(response)
      doc = Parser.string(response).parse
      data_block = doc.find("//OPS_envelope/body/data_block/*")

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
            next if item.empty?        
            arr[item.attributes["key"].to_i] = decode_data(item)
          end

          return arr
        when "dt_assoc"      
          hash = {}

          element.children.each do |item|
            next if item.empty?        
            hash[item.attributes["key"]] = decode_data(item)
          end

          return hash
        when "text", "item", "dt_scalar"
          next if element.empty?
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
      dt_array = Node.new("dt_array")

      data.each_with_index do |item, index|
        item_node = Node.new("item")
        item_node["key"] = index.to_s
        item_node << encode_data(item, item_node)

        dt_array << item_node
      end
      
      return dt_array
    end

    def self.encode_dt_assoc(data, container)  
      dt_assoc = Node.new("dt_assoc")

      data.each do |key, value|
        item_node = Node.new("item")
        item_node["key"] = key.to_s
        item_node << encode_data(value, item_node)

        dt_assoc << item_node
      end
      
      return dt_assoc
    end
  end
end