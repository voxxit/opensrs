OpenSRS::Server.xml_processor = :libxml

describe OpenSRS::XmlProcessor::Libxml do
  describe ".build" do
    it "should create XML for a nested hash" do
      attributes = {:foo => {:bar => 'baz'}}
      xml = OpenSRS::XmlProcessor::Libxml.build(attributes)

      expect(xml).to eq %{<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<OPS_envelope>\n  <header>\n    <version>0.9</version>\n  </header>\n  <body>\n    <data_block>\n      <dt_assoc>\n        <item key=\"foo\">\n          <dt_assoc>\n            <item key=\"bar\">baz</item>\n          </dt_assoc>\n        </item>\n      </dt_assoc>\n    </data_block>\n  </body>\n</OPS_envelope>\n}
    end
  end

  describe '.encode_data' do
    context "on a 3 element array" do
      before(:each) do
        @e = OpenSRS::XmlProcessor::Libxml.encode_data([1,2,3])
      end

      it "is a REXML::Element" do
        expect(@e).to be_an_instance_of(LibXML::XML::Node)
      end

      it "is a dt_array" do
        expect(@e.name).to eql("dt_array")
      end

      it "has 3 children all called <item>" do
        expect(@e.children.count).to be(3)
        expect(@e.children[0].name).to eql("item")
        expect(@e.children[1].name).to eql("item")
        expect(@e.children[2].name).to eql("item")
      end

      it "has children with keys 0, 1 and 2" do
        expect(@e.children[0].attributes["key"]).to eql("0")
        expect(@e.children[1].attributes["key"]).to eql("1")
        expect(@e.children[2].attributes["key"]).to eql("2")
      end
    end

    context "on a hash" do
      before(:each) do
        @e = OpenSRS::XmlProcessor::Libxml.encode_data({:name => "kitteh"})
      end

      it "is a REXML::Element" do
        expect(@e).to be_an_instance_of(LibXML::XML::Node)
      end

      it "is a dt_assoc" do
        expect(@e.name).to eql("dt_assoc")
      end

      it "has an <item> child with the right key" do
        expect(@e.children.count).to be(1)
        expect(@e.children[0].name).to eql("item")
        expect(@e.children[0].attributes["key"]).to eql("name")
      end
    end

    context "on a nested hash" do
      before(:each) do
        @e = OpenSRS::XmlProcessor::Libxml.encode_data({
          :suggestion => {
            :maximum => "10"
          }
        })
      end

      it "is a REXML::Element" do
        expect(@e).to be_an_instance_of(LibXML::XML::Node)
      end

      it "is a dt_assoc" do
        expect(@e.name).to eql("dt_assoc")
      end

      it "has an <item> child with the correct children" do
        expect(@e.children.count).to be(1)

        suggestion = @e.children[0]

        expect(suggestion.name).to eql("item")
        expect(suggestion.attributes["key"]).to eql("suggestion")
        expect(suggestion.children.count).to be(1)

        dt_assoc = suggestion.children[0]

        expect(dt_assoc.name).to eql("dt_assoc")
        expect(dt_assoc.children.count).to be(1)

        maximum = dt_assoc.children[0]

        expect(maximum.name).to eql("item")
        expect(maximum.attributes["key"]).to eql("maximum")
      end
    end

    context "produces a scalar" do
      it "from a string" do
        expect(OpenSRS::XmlProcessor::Libxml.encode_data("cheezburger")).to eql("cheezburger")
      end

      it "from a string with XML characters" do
        expect(OpenSRS::XmlProcessor::Libxml.encode_data("<smile>")).to eql("<smile>")
      end

      it "from an integer" do
        expect(OpenSRS::XmlProcessor::Libxml.encode_data(12345)).to eql("12345")
      end

      it "from a date" do
        date = Date.parse("2010/02/12")
        expect(OpenSRS::XmlProcessor::Libxml.encode_data(date)).to eql("2010-02-12")
      end

      it "from a symbol" do
        expect(OpenSRS::XmlProcessor::Libxml.encode_data(:name)).to eql("name")
      end

      it "from true or false" do
        expect(OpenSRS::XmlProcessor::Libxml.encode_data(true)).to eql("true")
        expect(OpenSRS::XmlProcessor::Libxml.encode_data(false)).to eql("false")
      end
    end
  end

  describe '.parse' do
    it "should handle scalar values" do
      xml = %{<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
        <!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
        <OPS_envelope>
          <header>
            <version>1.0</version>
          </header>
          <body>
            <data_block>
              <dt_scalar>Tom Jones</dt_scalar>
            </data_block>
          </body>
        </OPS_envelope>}

      expect(OpenSRS::XmlProcessor::Libxml.parse(xml)).to eql("Tom Jones")
    end

    it "should handle associate arrays with arrays of values" do
      xml = %{<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
      <!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
      <OPS_envelope>
        <header>
          <version>1.0</version>
        </header>
        <body>
          <data_block>
            <dt_assoc>
              <item key='domain_list'>
                <dt_array>
                  <item key='0'>ns1.example.com</item>
                  <item key='1'>ns2.example.com</item>
                  <item key='2'>ns3.example.com</item>
                </dt_array>
              </item>
            </dt_assoc>
          </data_block>
        </body>
      </OPS_envelope>}

      resp = OpenSRS::XmlProcessor::Libxml.parse(xml)

      expect(resp["domain_list"]).to be_an_instance_of Array
      expect(resp["domain_list"][0]).to eql("ns1.example.com")
      expect(resp["domain_list"][1]).to eql("ns2.example.com")
      expect(resp["domain_list"][2]).to eql("ns3.example.com")
    end

    it "should handle associative arrays containing other associative arrays" do
      xml = %{<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
      <!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
      <OPS_envelope>
        <header>
          <version>1.0</version>
        </header>
        <body>
          <data_block>
            <dt_assoc>
              <item key="contact_set">
                <dt_assoc>
                  <item key='owner'>
                    <dt_assoc>
                      <item key='first_name'>Tom</item>
                      <item key='last_name'>Jones</item>
                    </dt_assoc>
                  </item>
                  <item key='tech'>
                    <dt_assoc>
                      <item key='first_name'>Anne</item>
                      <item key='last_name'>Smith</item>
                    </dt_assoc>
                  </item>
                </dt_assoc>
              </item>
            </dt_assoc>
          </data_block>
        </body>
      </OPS_envelope>}

      resp = OpenSRS::XmlProcessor::Libxml.parse(xml)

      expect(resp["contact_set"]["owner"]["first_name"]).to eql("Tom")
      expect(resp["contact_set"]["owner"]["last_name"]).to eql("Jones")
      expect(resp["contact_set"]["tech"]["first_name"]).to eql("Anne")
      expect(resp["contact_set"]["tech"]["last_name"]).to eql("Smith")
    end

    context "with a balance enquiry example response" do
      before(:each) do
        xml = %{<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
          <!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
          <OPS_envelope>
            <header>
              <version>0.9</version>
            </header>
            <body>
              <data_block>
                <dt_assoc>
                  <item key="protocol">XCP</item>
                  <item key="action">REPLY</item>
                  <item key="object">BALANCE</item>
                  <item key="is_success">1</item>
                  <item key="response_code">200</item>
                  <item key="response_text">Command successful</item>
                  <item key="attributes">
                    <dt_assoc>
                      <item key="balance">8549.18</item>
                      <item key="hold_balance">1676.05</item>
                    </dt_assoc>
                  </item>
                </dt_assoc>
              </data_block>
            </body>
          </OPS_envelope>}

        @resp = OpenSRS::XmlProcessor::Libxml.parse(xml)
      end

      it "produces a hash" do
        expect(@resp).to be_an_instance_of Hash
      end

      it "has top level keys" do
        expect(@resp["protocol"]).to eql("XCP")
        expect(@resp["action"]).to eql("REPLY")
        expect(@resp["object"]).to eql("BALANCE")
      end

      it "has second level keys" do
        expect(@resp["attributes"]["balance"]).to eql("8549.18")
        expect(@resp["attributes"]["hold_balance"]).to eql("1676.05")
      end
    end
  end
end
