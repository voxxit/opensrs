describe OpenSRS::SanitizableString do
  subject(:sanitized_string) { described_class.new('string', 'sanitized string') }

  describe 'sanitizing enabled' do
    before do
      described_class.enable_sanitization = true
    end

    it 'returns the sanitized string when asked' do
      expect(sanitized_string.sanitized).to eql 'sanitized string'
    end

    it 'delegates all string functionality to the original string' do
      expect(sanitized_string.upcase).to eql 'string'.upcase
      expect(sanitized_string.length).to be 6
    end
  end

  describe 'sanitizing disabled' do
    before do
      described_class.enable_sanitization = false
    end

    it 'returns the original string when asked for a sanitized string' do
      expect(sanitized_string.sanitized).to eql 'string'
    end

    it 'delegates all string functionality to the original string' do
      expect(sanitized_string.upcase).to eql 'string'.upcase
      expect(sanitized_string.length).to be 6
    end
  end
end
