require 'spec_helper'
require 'date'

describe OpenSRS::XML do
  describe '#encode_data' do
    context "on a 3 element array" do
      before(:each) do
        @e = OpenSRS::XML.encode_data([1,2,3])
      end
      
      it "is a REXML::Element" do
        @e.should be_an_instance_of(LibXML::XML::Node)
      end

      it "is a dt_array" do
        @e.name.should == 'dt_array'
      end

      it "has 3 children all called <item>" do
        @e.should have(3).children
        @e.children[0].name.should == "item"
        @e.children[1].name.should == "item"
        @e.children[2].name.should == "item"
      end

      it "has children with keys 0, 1 and 2" do
        @e.children[0].attributes["key"].should == "0"
        @e.children[1].attributes["key"].should == "1"
        @e.children[2].attributes["key"].should == "2"
      end
    end

    context "on a hash" do
      before(:each) do
        @e = OpenSRS::XML.encode_data({:name => "kitteh"})
      end

      it "is a REXML::Element" do
        @e.should be_an_instance_of(LibXML::XML::Node)
      end

      it "is a dt_assoc" do
        @e.name.should == 'dt_assoc'
      end

      it "has an <item> child with the right key" do
        @e.should have(1).children
        @e.children[0].name.should == 'item'
        @e.children[0].attributes["key"].should == 'name'
      end
    end

    context "produces a scalar" do
      it "from a string" do
        OpenSRS::XML.encode_data("cheezburger").to_s.should == "cheezburger"
      end

      it "from a string with XML characters" do
        OpenSRS::XML.encode_data("<smile>").to_s.should == "<smile>"
      end

      it "from an integer" do
        OpenSRS::XML.encode_data(12345).to_s.should == "12345"
      end

      it "from a date" do
        date = Date.parse("2010/02/12")
        OpenSRS::XML.encode_data(date).to_s.should == "2010-02-12"
      end

      it "from a symbol" do
        OpenSRS::XML.encode_data(:name).to_s.should == "name"
      end

      it "from true or false" do
        OpenSRS::XML.encode_data(true).to_s.should == "true"
        OpenSRS::XML.encode_data(false).to_s.should == "false"
      end
    end
  end

  describe '#parse' do
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
        
      resp = OpenSRS::XML.parse(xml)
      resp.should == "Tom Jones"
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
        
      resp = OpenSRS::XML.parse(xml)
      resp["domain_list"].class.should == Array
      resp["domain_list"][0].should == "ns1.example.com"
      resp["domain_list"][1].should == "ns2.example.com"
      resp["domain_list"][2].should == "ns3.example.com"
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
      
      resp = OpenSRS::XML.parse(xml)
      
      resp["contact_set"]["owner"]["first_name"].should == "Tom"
      resp["contact_set"]["owner"]["last_name"].should == "Jones"
      resp["contact_set"]["tech"]["first_name"].should == "Anne"
      resp["contact_set"]["tech"]["last_name"].should == "Smith"
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
        
        @resp = OpenSRS::XML.parse(xml)
      end

      it "produces a hash" do
        @resp.should be_an_instance_of(Hash)
      end

      it "has top level keys" do
        @resp["protocol"].should == "XCP"
        @resp["action"].should == "REPLY"
        @resp["object"].should == "BALANCE"
      end

      it "has second level keys" do
        @resp["attributes"]["balance"].should == "8549.18"
        @resp["attributes"]["hold_balance"].should == "1676.05"
      end
    end
  end
end