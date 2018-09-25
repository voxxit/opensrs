# frozen_string_literal: true

describe OpenSRS::SanitizableString do
  subject { described_class.new("string", "sanitized string") }
  describe "sanitizing enabled" do
    before(:each) do
      described_class.enable_sanitization = true
    end
    it "returns the sanitized string when asked" do
      expect(subject.sanitized).to eql "sanitized string"
    end

    it "delegates all string functionality to the original string" do
      expect(subject.upcase).to eql "string".upcase
      expect(subject.length).to eql 6
    end
  end

  describe "sanitizing disabled" do
    before(:each) do
      described_class.enable_sanitization = false
    end
    it "returns the original string when asked for a sanitized string" do
      expect(subject.sanitized).to eql "string"
    end

    it "delegates all string functionality to the original string" do
      expect(subject.upcase).to eql "string".upcase
      expect(subject.length).to eql 6
    end
  end
end
