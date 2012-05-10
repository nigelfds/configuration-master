require "uri"
require "json"
require "net/http"

class SystemIntegrationPipeline
  def initialize
    raise "This class is supposed to be used in a Go pipeline" unless ENV.has_key? "GO_SERVER_URL"
  end

  def aws_twitter_feed_artifact
    fetch_artifact "APP", "rpms"
  end

  def configuration_master_artifact
    fetch_artifact "CONFIGURATION", "build"
  end

  def fetch_artifact(pipeline_name, artifact_dir)
    variable_name = "GO_DEPENDENCY_LOCATOR_UPSTREAMARTIFACT#{pipeline_name}"
    uri = "http://#{hostname}:8153/go/files/#{ENV[variable_name]}/package.json"
    puts "Fetching artifact from #{uri}"
    response = Net::HTTP.get_response(URI(uri))
    json = JSON.parse(response.body)
    json.find { |element| element["name"].eql? artifact_dir }["files"].first["url"]
  end

  def hostname
    %x{ec2-metadata -p}.chomp.split(":")[1].strip
  end
end
