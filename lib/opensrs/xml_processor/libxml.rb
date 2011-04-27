require "libxml"

module OpenSRS
  class XmlProcessor::Libxml < OpenSRS::XmlProcessor
    include ::LibXML::XML
    
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

    protected

    def self.data_block_element(response)
      doc = Parser.string(response).parse
      return doc.find("//OPS_envelope/body/data_block/*")
    end
    
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