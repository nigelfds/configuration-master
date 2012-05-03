require "spec_helper"
require "net/http"

describe "Go server" do
  before :all do
    ENV["BOOT_PACKAGE_URL"] = "file:///home/vagrant/configuration-master/build/puppet.tar.gz"
    VAGRANT.cli("up")
  end

  after :all do
    VAGRANT.cli("destroy", "-f") unless ENV.has_key? "FAST"
  end

  it "should run on port 8153" do
    puts Net::HTTP.get("localhost:8153", "/index.html")
  end
end
