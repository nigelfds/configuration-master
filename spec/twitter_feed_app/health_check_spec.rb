require "spec_helper"
require "nokogiri"
require "excon"

describe "Twitter Feed App Health Check" do
  it "should successfully display twitter statuses for the default hash tag" do
    response = Excon.get('http://localhost:8080')
    response.status.should == 200

    html = Nokogiri::HTML.parse(response.body)
    html.css('#hash_tag').text.should == "#aws"
    html.css('#tweets .tweet').length.should > 0
  end
end