describe OpenSRS::Response do
  let(:successful_response) { { 'response_text' => 'Yay!', 'response_code' => 200, 'is_success' => '1' } }
  let(:failed_response)     { { 'response_text' => 'No :(', 'response_code' => 404, 'is_success' => '0' } }
  let(:unknown_response)    { { 'response_text' => 'No :(', 'is_success' => '0' } }
  let(:request_xml)         { double }
  let(:response_xml)        { double }

  describe '#errors' do
    it 'returns nil for successful responses' do
      response = described_class.new(successful_response, request_xml, response_xml)

      expect(response.success?).to be true
      expect(response.errors).to be_nil
    end

    it 'returns a formatted error message and code' do
      response = described_class.new(failed_response, request_xml, response_xml)

      expect(response.success?).to be false
      expect(response.errors).to eql('No :( (Code 404)')
    end

    it "returns 'Unknown error' if no error code is available" do
      response = described_class.new(unknown_response, request_xml, response_xml)

      expect(response.success?).to be false
      expect(response.errors).to eql('Unknown error')
    end

    it "returns 'Unknown error' if no error text is available" do
      response = described_class.new(failed_response.delete('response_text'), request_xml, response_xml)

      expect(response.success?).to be false
      expect(response.errors).to eql('Unknown error')
    end
  end
end
