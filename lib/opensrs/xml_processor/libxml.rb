begin
  require 'libxml'
rescue LoadError => e
  $stderr.puts "Cannot find `libxml` gem. Please install it before using it as the XML processor"
  raise e
end

module OpenSRS
  class XmlProcessor
    class Libxml < OpenSRS::XmlProcessor
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

      def self.decode_dt_array_data(element)
        dt_array = []

        element.children.each do |item|
          next if item.empty?
          dt_array[item.attributes["key"].to_i] = decode_data(item)
        end

        return dt_array
      end

      def self.decode_dt_assoc_data(element)
        dt_assoc = {}

        element.children.each do |item|
          if item.children.empty?
            dt_assoc[item.attributes["key"]] = ""
          else
            dt_assoc[item.attributes["key"]] = decode_data(item)
          end
        end

        return dt_assoc
      end

      # Accepts two parameters but uses only one; to keep the interface same as other xml parser classes
      # Is that a side effect of Template pattern?
      #
      def self.new_element(element_name, container)
        return Node.new(element_name.to_s)
      end

    end
  end
end
