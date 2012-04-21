Vagrant::Config.run do |config|
  config.vm.define :configuration_master do |configuration|
    configuration.vm.box = "centos57_32Netcool"
    configuration.vm.box_url = 'http://artifactory.nbnco.net.au/netcool/VM/centos57_32Netcool.box'
    configuration.vm.customize [
      "modifyvm", :id,
      "--name", "configuration-master",
      "--memory", "1024"
    ]
    configuration.vm.host_name = "configuration-master"
    # configuration.vm.network :hostonly, "33.33.33.15"
    configuration.vm.share_folder ".", "/home/vagrant/configuration-master", "."
    configuration.vm.provision :shell, :path => "lib/provision.sh"
  end
end