require 'spec_helper'
require 'date'

describe OpenSRS::XmlProcessor::Nokogiri do
  describe ".build" do
    it "should create XML for a nested hash" do
      attributes = {:foo => {:bar => 'baz'}}
      xml = OpenSRS::XmlProcessor::Nokogiri.build(attributes)
      xml.should eq %{<?xml version=\"1.0\"?>\n<OPS_envelope>\n  <header>\n    <version>0.9</version>\n  </header>\n  <body>\n    <data_block>\n      <dt_assoc>\n        <item key=\"foo\">\n          <dt_assoc>\n            <item key=\"bar\">baz</item>\n          </dt_assoc>\n        </item>\n      </dt_assoc>\n    </data_block>\n  </body>\n</OPS_envelope>\n}
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

      it { @e.should be_an_instance_of(::Nokogiri::XML::Element) }
      it { @e.name.should eql('dt_array') }

      it { @e.should have(3).children }
      it { @e.children[0].name.should eql("item") }
      it { @e.children[1].name.should eql("item") }
      it { @e.children[2].name.should eql("item") }

      it { @e.children[0].attributes["key"].value.should eql("0") }
      it { @e.children[1].attributes["key"].value.should eql("1") }
      it { @e.children[2].attributes["key"].value.should eql("2") }
    end

    context "on a hash" do
      before(:each) do
        @e = OpenSRS::XmlProcessor::Nokogiri.encode_data({:name => "kitteh"}, @doc)
      end

      it { @e.should be_an_instance_of(::Nokogiri::XML::Element) }
      it { @e.name.should eql('dt_assoc') }

      it { @e.should have(1).children }
      it { @e.children[0].name.should eql('item') }
      it { @e.children[0].attributes["key"].value.should eql('name') }
    end

    context "on a nested hash" do
      before(:each) do
        @e          = OpenSRS::XmlProcessor::Nokogiri.encode_data({:suggestion => {:maximum => "10"}}, @doc)
        @suggestion = @e.children[0]
        @dt_assoc   = @suggestion.children[0]
      end

      it { @e.should be_an_instance_of(::Nokogiri::XML::Element) }
      it { @e.name.should == 'dt_assoc' }

      context "<item> child" do
        it { @e.should have(1).children }
        it { @suggestion.name.should eql('item') }
        it { @suggestion.attributes["key"].value.should eql('suggestion') }
      end

      context "suggesion children" do
        it { @suggestion.should have(1).children }
        it { @dt_assoc.name.should eql('dt_assoc') }
      end

      context "dt_assoc children" do
        before(:each) do
          @maximum = @dt_assoc.children[0]
        end
        it { @dt_assoc.should have(1).children }
        it { @maximum.name.should eql('item') }
        it { @maximum.attributes["key"].value.should eql('maximum') }
      end
    end

    context "produces a scalar" do
      it { OpenSRS::XmlProcessor::Nokogiri.encode_data("cheezburger").to_s.should eql("cheezburger") }
      it { OpenSRS::XmlProcessor::Nokogiri.encode_data("<smile>").to_s.should eql("<smile>") }

      it { OpenSRS::XmlProcessor::Nokogiri.encode_data(12345).to_s.should eql("12345") }
      it { OpenSRS::XmlProcessor::Nokogiri.encode_data(Date.parse("2010/02/12")).to_s.should eql("2010-02-12") }
      it { OpenSRS::XmlProcessor::Nokogiri.encode_data(:name).to_s.should eql("name") }
      it { OpenSRS::XmlProcessor::Nokogiri.encode_data(true).to_s.should eql("true") }
      it { OpenSRS::XmlProcessor::Nokogiri.encode_data(false).to_s.should eql("false") }
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

      it { @response.should eql("Tom Jones") }
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

      it { @response["domain_list"].class.should eql(Array) }
      it { @response["domain_list"][0].should eql("ns1.example.com") }
      it { @response["domain_list"][1].should eql("ns2.example.com") }
      it { @response["domain_list"][2].should eql("ns3.example.com") }
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
      it { @response["contact_set"]["owner"]["first_name"].should eql("Tom") }
      it { @response["contact_set"]["owner"]["last_name"].should eql("Jones") }
      it { @response["contact_set"]["tech"]["first_name"].should eql("Anne") }
      it { @response["contact_set"]["tech"]["last_name"].should eql("Smith") }
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

      it { @response.should be_an_instance_of(Hash) }
      it { @response["protocol"].should eql("XCP") }
      it { @response["action"].should eql("REPLY") }
      it { @response["object"].should eql("BALANCE") }
      it { @response["attributes"]["balance"].should eql("8549.18") }
      it { @response["attributes"]["hold_balance"].should eql("1676.05") }

    end
  end
end