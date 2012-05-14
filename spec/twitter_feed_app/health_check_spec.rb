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
    html = get_twitter_statuses(@app_url)

    html.css('#hash_tag').text.should == "#aws"
    html.css('#tweets .tweet').length.should > 0
  end

  def get_twitter_statuses(url)
    retries = 20
    html = ""
    while retries > 0 && html.empty?
      begin
        response = Excon.get(url)
        if response.status == 200
          html = Nokogiri::HTML.parse(response.body)
        else
          raise "Response status: #{response.status}, Retying..."
        end
      rescue => e
        $stderr.puts "Failed to get Twitter statuses from #{url}: #{e.message}"
        $stderr.puts "Retrying..."
        sleep 15
      end
      retries -= 1
    end
    html
  end
end