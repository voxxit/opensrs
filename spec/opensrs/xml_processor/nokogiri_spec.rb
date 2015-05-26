OpenSRS::Server.xml_processor = :nokogiri

describe OpenSRS::XmlProcessor::Nokogiri do
  describe ".build" do
    it "should create XML for a nested hash" do
      attributes = {:foo => {:bar => 'baz'}}
      xml = OpenSRS::XmlProcessor::Nokogiri.build(attributes)

      expect(xml).to eq %{<?xml version=\"1.0\"?>\n<OPS_envelope>\n  <header>\n    <version>0.9</version>\n  </header>\n  <body>\n    <data_block>\n      <dt_assoc>\n        <item key=\"foo\">\n          <dt_assoc>\n            <item key=\"bar\">baz</item>\n          </dt_assoc>\n        </item>\n      </dt_assoc>\n    </data_block>\n  </body>\n</OPS_envelope>\n}
    end
  end

  describe '.encode_data' do

    before(:each) do
      @builder = ::Nokogiri::XML::Builder.new
      @doc     = @builder.doc
    end

    context "on a 3 element array" do
      before(:each) do
        @e = OpenSRS::XmlProcessor::Nokogiri.encode_data([1,2,3], @doc)
      end

      it { expect(@e).to be_an_instance_of(::Nokogiri::XML::Element) }
      it { expect(@e.name).to eql('dt_array') }

      it { expect(@e.children.count).to be(3) }
      it { expect(@e.children[0].name).to eql("item") }
      it { expect(@e.children[1].name).to eql("item") }
      it { expect(@e.children[2].name).to eql("item") }

      it { expect(@e.children[0].attributes["key"].value).to eql("0") }
      it { expect(@e.children[1].attributes["key"].value).to eql("1") }
      it { expect(@e.children[2].attributes["key"].value).to eql("2") }
    end

    context "on a hash" do
      before(:each) do
        @e = OpenSRS::XmlProcessor::Nokogiri.encode_data({:name => "kitteh"}, @doc)
      end

      it { expect(@e).to be_an_instance_of(::Nokogiri::XML::Element) }
      it { expect(@e.name).to eql('dt_assoc') }

      it { expect(@e.children.count).to be(1) }
      it { expect(@e.children[0].name).to eql('item') }
      it { expect(@e.children[0].attributes["key"].value).to eql('name') }
    end

    context "on a hash subclass" do
      before(:each) do
        ohash = OrderedHash.new
        ohash[:name] = 'kitten'
        @e = OpenSRS::XmlProcessor::Nokogiri.encode_data(ohash, @doc)
      end

      it { expect(@e).to be_an_instance_of(::Nokogiri::XML::Element) }
      it { expect(@e.name).to eql('dt_assoc') }

      it { expect(@e.children.count).to be(1) }
      it { expect(@e.children[0].name).to eql('item') }
      it { expect(@e.children[0].attributes["key"].value).to eql('name') }
    end


    context "on a nested hash" do
      before(:each) do
        @e          = OpenSRS::XmlProcessor::Nokogiri.encode_data({:suggestion => {:maximum => "10"}}, @doc)
        @suggestion = @e.children[0]
        @dt_assoc   = @suggestion.children[0]
      end

      it { expect(@e).to be_an_instance_of(::Nokogiri::XML::Element) }
      it { expect(@e.name).to eql("dt_assoc") }

      context "<item> child" do
        it { expect(@e.children.count).to be(1) }
        it { expect(@suggestion.name).to eql('item') }
        it { expect(@suggestion.attributes["key"].value).to eql('suggestion') }
      end

      context "suggesion children" do
        it { expect(@suggestion.children.count).to be(1) }
        it { expect(@dt_assoc.name).to eql('dt_assoc') }
      end

      context "dt_assoc children" do
        before(:each) do
          @maximum = @dt_assoc.children[0]
        end

        it { expect(@dt_assoc.children.count).to be(1) }
        it { expect(@maximum.name).to eql('item') }
        it { expect(@maximum.attributes["key"].value).to eql('maximum') }
      end
    end

    context "produces a scalar" do
      it { expect(OpenSRS::XmlProcessor::Nokogiri.encode_data("cheezburger")).to eql("cheezburger") }
      it { expect(OpenSRS::XmlProcessor::Nokogiri.encode_data("<smile>")).to eql("<smile>") }

      it { expect(OpenSRS::XmlProcessor::Nokogiri.encode_data(12345)).to eql("12345") }
      it { expect(OpenSRS::XmlProcessor::Nokogiri.encode_data(Date.parse("2010/02/12"))).to eql("2010-02-12") }
      it { expect(OpenSRS::XmlProcessor::Nokogiri.encode_data(:name)).to eql("name") }
      it { expect(OpenSRS::XmlProcessor::Nokogiri.encode_data(true)).to eql("true") }
      it { expect(OpenSRS::XmlProcessor::Nokogiri.encode_data(false)).to eql("false") }
    end
  end

  describe '.parse' do

    context "when scaler values" do
      before(:each) do
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

        @response = OpenSRS::XmlProcessor::Nokogiri.parse(xml)
      end

      it { expect(@response).to eql("Tom Jones") }
    end

    context "when associative arrays with arrays of values" do
      before(:each) do
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

        @response = OpenSRS::XmlProcessor::Nokogiri.parse(xml)
      end

      it { expect(@response["domain_list"]).to be_an_instance_of(Array) }
      it { expect(@response["domain_list"][0]).to eql("ns1.example.com") }
      it { expect(@response["domain_list"][1]).to eql("ns2.example.com") }
      it { expect(@response["domain_list"][2]).to eql("ns3.example.com") }
    end

    context "when associative arrays containing other associative arrays" do
      before(:each) do
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

        @response = OpenSRS::XmlProcessor::Nokogiri.parse(xml)
      end

      it { expect(@response["contact_set"]["owner"]["first_name"]).to eql("Tom") }
      it { expect(@response["contact_set"]["owner"]["last_name"]).to eql("Jones") }
      it { expect(@response["contact_set"]["tech"]["first_name"]).to eql("Anne") }
      it { expect(@response["contact_set"]["tech"]["last_name"]).to eql("Smith") }
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

        @response = OpenSRS::XmlProcessor::Nokogiri.parse(xml)
      end

      it { expect(@response).to be_an_instance_of(Hash) }
      it { expect(@response["protocol"]).to eql("XCP") }
      it { expect(@response["action"]).to eql("REPLY") }
      it { expect(@response["object"]).to eql("BALANCE") }
      it { expect(@response["attributes"]["balance"]).to eql("8549.18") }
      it { expect(@response["attributes"]["hold_balance"]).to eql("1676.05") }

    end
  end
end
