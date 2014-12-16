describe OpenSRS::Version do
  describe "VERSION" do
    it "should return version string" do
      OpenSRS::Version::VERSION.should eql("0.3.4")
    end
  end
end
