require 'spec_helper'
require 'date'

describe OpenSRS::XML do
  describe '#encode' do
    context "on a 3 element array" do
      before(:each) do
        @e = OpenSRS::XML.encode([1,2,3])
      end
      it "is a REXML::Element" do
        @e.should be_an_instance_of(REXML::Element)
      end

      it "is a dt_array" do
        @e.name.should == 'dt_array'
      end

      it "has 3 children all called <item>" do
        @e.should have(3).children
        @e[0].name.should == "item"
        @e[1].name.should == "item"
        @e[2].name.should == "item"
      end

      it "has children with keys 0, 1 and 2" do
        @e[0].attributes["key"].should == "0"
        @e[1].attributes["key"].should == "1"
        @e[2].attributes["key"].should == "2"
      end
    end

    context "on a hash" do
      before(:each) do
        @e = OpenSRS::XML.encode({:name => "kitteh"})
      end

      it "is a REXML::Element" do
        @e.should be_an_instance_of(REXML::Element)
      end

      it "is a dt_assoc" do
        @e.name.should == 'dt_assoc'
      end

      it "has an <item> child with the right key" do
        @e.should have(1).child
        @e[0].name.should == 'item'
        @e[0].attributes["key"].should == 'name'
      end
    end

    context "produces a scalar" do
      it "from a string" do
        OpenSRS::XML.encode("cheezburger").to_s.should == "<dt_scalar>cheezburger</dt_scalar>"
      end

      it "from a string with XML characters" do
        OpenSRS::XML.encode("<smile>").to_s.should == "<dt_scalar>&lt;smile&gt;</dt_scalar>"
      end

      it "from an integer" do
        OpenSRS::XML.encode(12345).to_s.should == "<dt_scalar>12345</dt_scalar>"
      end

      it "from a date" do
        date = Date.parse("2010/02/12")
        OpenSRS::XML.encode(date).to_s.should == "<dt_scalar>2010-02-12</dt_scalar>"
      end

      it "from a symbol" do
        OpenSRS::XML.encode(:name).to_s.should == "<dt_scalar>name</dt_scalar>"
      end

      it "from true or false" do
        OpenSRS::XML.encode(true).to_s.should == "<dt_scalar>true</dt_scalar>"
        OpenSRS::XML.encode(false).to_s.should == "<dt_scalar>false</dt_scalar>"
      end
    end
  end

  describe '#parse' do
    context "with a balance enquiry example response" do
      before(:each) do
        xml = <<-'EOF'
          <?xml version='1.0' encoding='UTF-8' standalone='no' ?> <!DOCTYPE OPS_envelope SYSTEM 'ops.dtd'>
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
          </OPS_envelope>
        EOF
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

  describe '#decode' do
    it "does basic things" do
      OpenSRS::XML.decode("1").should == "1"
      OpenSRS::XML.decode("Hello").should == "Hello"
      OpenSRS::XML.decode("&lt;grin&gt;").should == "<grin>"
      OpenSRS::XML.decode('<dt_scalar>Hello</dt_scalar>').should == "Hello"
      OpenSRS::XML.decode('<dt_assoc><item key="name">Bob</item></dt_assoc>').should == { "name" => "Bob" }
      OpenSRS::XML.decode('<dt_array><item key="0">1</item><item key="1">2</item></dt_array>').should == ["1", "2"]
    end
  end
end
