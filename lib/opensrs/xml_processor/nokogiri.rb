begin
  require 'nokogiri'
rescue LoadError => e
  $stderr.puts "Cannot find Nokogiri gem. Please install Nokogiri before using it as the xml processor\n\n"
  raise e
end

module OpenSRS
  class XmlProcessor::Nokogiri < OpenSRS::XmlProcessor

    def self.build(data)
      builder = ::Nokogiri::XML::Builder.new

      envelope   = ::Nokogiri::XML::Node.new("OPS_envelope", builder.doc)
      header     = ::Nokogiri::XML::Node.new("header", builder.doc)
      version    = ::Nokogiri::XML::Node.new("version", builder.doc)
      body       = ::Nokogiri::XML::Node.new("body", builder.doc)
      data_block = ::Nokogiri::XML::Node.new("data_block", builder.doc)
      other_data = encode_data(data, builder.doc)
      builder.doc << ( envelope << ( header << ( version << '0.9') ) )
      envelope << ( body << ( data_block << other_data ) )
      return builder.to_xml
    end

    protected

    def self.data_block_element(response)
      doc = ::Nokogiri::XML(response)
      return doc.xpath('//OPS_envelope/body/data_block/*')
    end

    def self.decode_dt_array_data(element)
      dt_array = []

      element.children.each do |item|
        next if item.content.strip.empty?
        dt_array[item.attributes["key"].value.to_i] = decode_data(item.children)
      end

      return dt_array
    end

    def self.decode_dt_assoc_data(element)
      dt_assoc = {}

      element.children.each do |item|
        next if item.content.strip.empty?
        dt_assoc[item.attributes["key"].value] = decode_data(item.children)
      end

      return dt_assoc
    end

    def self.new_element(element_name, container)
      return ::Nokogiri::XML::Node.new(element_name.to_s, container)
    end

  end
end
