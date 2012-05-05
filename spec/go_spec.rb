require "spec_helper"
require "net/http"

describe "Go server" do
  before :all do
    %x{./go clean package:puppet}
    ENV["role"] = "buildserver"
    VAGRANT.cli("up")
  end

  after :all do
    VAGRANT.cli("destroy", "-f") unless ENV.has_key? "FAST"
  end

  it "should run on port 8153" do
    puts Net::HTTP.get("localhost:8153", "/index.html")
  end
end
