require 'rexml/document'

module OpenSRS
  class XML
    include REXML
    
    # First, builds REXML elements for the inputted data. Then, it will
    # go ahead and build the entire XML document to send to OpenSRS.
    def self.build(data)
      data = encode(data) unless data.kind_of?(REXML::Element)

      doc = Document.new
      doc << XMLDecl.new("1.0", "UTF-8", "no")
      doc << DocType.new("OPS_envelope", "SYSTEM 'ops.dtd'")

      root = Element.new("OPS_envelope", doc)

      Element.new("version", Element.new("header", root)).add_text("0.9")
      Element.new("data_block", Element.new("body", root)).add(data)

      return doc.to_s
    end

    # Encodes individual elements, and their child elements, for the root 
    # XML document.
    def self.encode(data)
      case data
      when Array
        element = Element.new("dt_array")

        data.each_with_index do |v, j|
          item = Element.new("item")
          item.add_attribute("key", j.to_s)
          item.add_element(encode(v)) 

          element.add_element(item)
        end

        return element
      when Hash
        element = Element.new("dt_assoc")

        data.each do |k, v|
          item = Element.new("item")
          item.add_attribute("key", k.to_s)
          item.add_element(encode(v))
          
          element.add_element(item)
        end

        return element
      when String, Numeric, Date, Time, Symbol, NilClass
        element = Element.new("dt_scalar")
        element.text = data.to_s

        return element
      else
        # Give up, probably wrong!
        return encode(data.inspect)
      end
    end

    # Parses the main data block from OpenSRS and discards
    # the rest of the response.
    def self.parse(response)
      response.gsub!(/<!DOCTYPE OPS_envelope SYSTEM "ops.dtd">/, "")
      response = Document.new(response) unless response.is_a?(REXML::Document)

      data_block_children = XPath.first(response, "//OPS_envelope/body/data_block/*")

      raise ArgumentError.new("No OPS_envelope found in document") unless data_block_children

      return decode(data_block_children)
    end

    # Decodes individual data elements from OpenSRS response.
    def self.decode(data)
      if data.is_a?(String)
        doc = Document.new(data)

        if doc.children.length == 1
          return decode(doc.children[0])
        else
          doc.children.map { |i| return decode(i) }
        end
      end

      # The OpenSRS server's response (and the client docs) don't always
      # encapsulate scalars in <dt_scalar> as you'd expect - so we have to
      # infer that unexpected raw text is always a scalar.
      return guess_scalar(data.value) if data.is_a?(REXML::Text)

      case data.name
      when "dt_array"
        array = []

        data.elements.each("item") do |item| 
          array[item.attributes["key"].to_i] = trim_and_decode(item.children)
        end

        return array
      when "dt_assoc"
        hash = {}

        data.elements.each("item") do |item|
          hash[item.attributes["key"]] = trim_and_decode(item.children)
        end

        return hash
      when /^dt_scalar(ref)?/ then return guess_scalar(data.value)
      end
    end

    protected

    # Tries to correctly parse individual text into Date, Time, or Integers.
    # If it fails, just displays the returned text.
    def self.guess_scalar(text)
      case text
      when /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$/ then Time.parse(text)
      when /^\d\d\d\d-\d\d-\d\d$/ then Date.parse(text)
      else
        text
      end
    end

    # Decodes lists, such as contact lists.
    def self.trim_and_decode(list)
      return "" if list.length.zero?
      return decode(list[0]) if list.length == 1
      
      first_non_text = list.select { |e| !e.kind_of?(REXML::Text) }[0]
      
      return decode(first_non_text) unless first_non_text.nil?
      return decode(list[0])
    end
  end
end