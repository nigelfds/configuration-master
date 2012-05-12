require "uri"
require "net/http"
require "go/pipeline"

module Go
  class ProductionDeployPipeline < Pipeline
    def initialize
      super
    end

    def upstream_artifact
      artifact_uri = artifact_location("SYSTEST", "build")
      Net::HTTP.get_response(URI(artifact_uri)).body.chomp
    end
  end
end
