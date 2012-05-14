require "spec_helper"
require "nokogiri"
require "excon"

describe "Twitter Feed App Health Check" do
  before :each do
    @app_url = "http://#{File.open("build/app-url", "r").read.strip}:8080"
    @app_url.should_not be_empty
    puts "Checking health of app at: #{@app_url}"
  end

  it "should successfully display twitter statuses for the default hash tag" do
    response = Excon.get(@app_url)
    response.status.should == 200

    html = Nokogiri::HTML.parse(response.body)
    html.css('#hash_tag').text.should == "#aws"
    html.css('#tweets .tweet').length.should > 0
  end
end