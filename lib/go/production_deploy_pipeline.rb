require "uri"
require "net/http"
require "pipeline"

class Go::ProductionDeployPipeline < Go::Pipeline
  def initialize
    super
  end

  def upstream_artifact
    artifact_uri = artifact_location("SYSTEST", "build")
    Net::HTTP.get_response(URI(pipeline.upstream_artifact)).body.chomp
  end
end
