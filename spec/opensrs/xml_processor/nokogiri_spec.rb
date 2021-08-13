OpenSRS::Server.xml_processor = :nokogiri

class OrderedHash < Hash
end

describe OpenSRS::XmlProcessor::Nokogiri do
  describe '.build' do
    let(:support_dir) do
      File.join(File.dirname(__FILE__), '..', '..', 'support', 'nokogiri')
    end
    let(:xml) do
      IO.read(File.join(support_dir, 'xml.xml'))
    end
    let(:xml_with_credentials) do
      IO.read(File.join(support_dir, 'xml_with_credentials.xml'))
    end
    let(:xml_with_sanitized_credentials) do
      IO.read(File.join(support_dir, 'xml_with_sanitized_credentials.xml'))
    end

    it 'creates XML for a nested hash' do
      attributes = { foo: { bar: 'baz' } }
      thexml = described_class.build(attributes)

      expect(thexml).to eq xml
    end

    it 'includes a sanitized version in the response' do
      OpenSRS::SanitizableString.enable_sanitization = true
      attributes = {
        foo: {
          bar: 'baz', reg_username: 'donaldduck', reg_password: 'secret123'
        },
        monkeys: {
          bar: 'foo', reg_username: 'mickeymouse', reg_password: 'secret456'
        }
      }
      xml = described_class.build(attributes)

      expect(xml).to eql xml_with_credentials
      expect(xml.sanitized).to eql xml_with_sanitized_credentials
    end

    it "encodes trailing '<'" do
      attributes = { foo: { bar: 'baz&<' } }
      xml = described_class.build(attributes)

      expect(xml).to eq %(<?xml version=\"1.0\"?>\n<OPS_envelope>\n  <header>\n    <version>0.9</version>\n  </header>\n  <body>\n    <data_block>\n      <dt_assoc>\n        <item key=\"foo\">\n          <dt_assoc>\n            <item key=\"bar\">baz&amp;&lt;</item>\n          </dt_assoc>\n        </item>\n      </dt_assoc>\n    </data_block>\n  </body>\n</OPS_envelope>\n)
    end
  end

  describe '.encode_data' do
    before do
      @builder = ::Nokogiri::XML::Builder.new
      @doc     = @builder.doc
    end

    context 'with a 3 element array' do
      before do
        @e = described_class.encode_data([1, 2, 3], @doc)
      end

      it { expect(@e).to be_an_instance_of(::Nokogiri::XML::Element) }
      it { expect(@e.name).to eql('dt_array') }

      it { expect(@e.children.count).to be(3) }
      it { expect(@e.children[0].name).to eql('item') }
      it { expect(@e.children[1].name).to eql('item') }
      it { expect(@e.children[2].name).to eql('item') }

      it { expect(@e.children[0].attributes['key'].value).to eql('0') }
      it { expect(@e.children[1].attributes['key'].value).to eql('1') }
      it { expect(@e.children[2].attributes['key'].value).to eql('2') }
    end

    context 'with a hash' do
      before do
        @e = described_class.encode_data({ name: 'kitteh' }, @doc)
      end

      it { expect(@e).to be_an_instance_of(::Nokogiri::XML::Element) }
      it { expect(@e.name).to eql('dt_assoc') }

      it { expect(@e.children.count).to be(1) }
      it { expect(@e.children[0].name).to eql('item') }
      it { expect(@e.children[0].attributes['key'].value).to eql('name') }
    end

    context 'with a hash subclass' do
      before do
        ohash = OrderedHash.new
        ohash[:name] = 'kitten'
        @e = described_class.encode_data(ohash, @doc)
      end

      it { expect(@e).to be_an_instance_of(::Nokogiri::XML::Element) }
      it { expect(@e.name).to eql('dt_assoc') }

      it { expect(@e.children.count).to be(1) }
      it { expect(@e.children[0].name).to eql('item') }
      it { expect(@e.children[0].attributes['key'].value).to eql('name') }
    end

    context 'with a nested hash' do
      before do
        @e          = described_class.encode_data({ suggestion: { maximum: '10' } }, @doc)
        @suggestion = @e.children[0]
        @dt_assoc   = @suggestion.children[0]
      end

      it { expect(@e).to be_an_instance_of(::Nokogiri::XML::Element) }
      it { expect(@e.name).to eql('dt_assoc') }

      context 'with <item> child' do
        it { expect(@e.children.count).to be(1) }
        it { expect(@suggestion.name).to eql('item') }
        it { expect(@suggestion.attributes['key'].value).to eql('suggestion') }
      end

      context 'with suggesion children' do
        it { expect(@suggestion.children.count).to be(1) }
        it { expect(@dt_assoc.name).to eql('dt_assoc') }
      end

      context 'with dt_assoc children' do
        before do
          @maximum = @dt_assoc.children[0]
        end

        it { expect(@dt_assoc.children.count).to be(1) }
        it { expect(@maximum.name).to eql('item') }
        it { expect(@maximum.attributes['key'].value).to eql('maximum') }
      end
    end

    context 'when produces a scalar' do
      it { expect(described_class.encode_data('cheezburger')).to eql('cheezburger') }
      it { expect(described_class.encode_data('<smile>')).to eql('<smile>') }

      it { expect(described_class.encode_data(12_345)).to eql('12345') }
      it { expect(described_class.encode_data(Date.parse('2010/02/12'))).to eql('2010-02-12') }
      it { expect(described_class.encode_data(:name)).to eql('name') }
      it { expect(described_class.encode_data(true)).to eql('true') }
      it { expect(described_class.encode_data(false)).to eql('false') }
    end
  end

  describe '.parse' do
    context 'when scaler values' do
      before do
        xml = %(<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
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
          </OPS_envelope>)

        @response = described_class.parse(xml)
      end

      it { expect(@response).to eql('Tom Jones') }
    end

    context 'when associative arrays with arrays of values' do
      before do
        xml = %(<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
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
        </OPS_envelope>)

        @response = described_class.parse(xml)
      end

      it { expect(@response['domain_list']).to be_an_instance_of(Array) }
      it { expect(@response['domain_list'][0]).to eql('ns1.example.com') }
      it { expect(@response['domain_list'][1]).to eql('ns2.example.com') }
      it { expect(@response['domain_list'][2]).to eql('ns3.example.com') }
    end

    context 'when associative arrays containing other associative arrays' do
      before do
        xml = %(<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
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
        </OPS_envelope>)

        @response = described_class.parse(xml)
      end

      it { expect(@response['contact_set']['owner']['first_name']).to eql('Tom') }
      it { expect(@response['contact_set']['owner']['last_name']).to eql('Jones') }
      it { expect(@response['contact_set']['tech']['first_name']).to eql('Anne') }
      it { expect(@response['contact_set']['tech']['last_name']).to eql('Smith') }
    end

    context 'with a balance enquiry example response' do
      before do
        xml = %(<?xml version='1.0' encoding='UTF-8' standalone='no' ?>
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
          </OPS_envelope>)

        @response = described_class.parse(xml)
      end

      it { expect(@response).to be_an_instance_of(Hash) }
      it { expect(@response['protocol']).to eql('XCP') }
      it { expect(@response['action']).to eql('REPLY') }
      it { expect(@response['object']).to eql('BALANCE') }
      it { expect(@response['attributes']['balance']).to eql('8549.18') }
      it { expect(@response['attributes']['hold_balance']).to eql('1676.05') }
    end
  end
end
