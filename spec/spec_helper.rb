require "vagrant"

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end

SSH_KEY = %x[vagrant ssh-config | grep IdentityFile].split[1]
VAGRANT_CONF = File.join(File.expand_path(File.dirname(__FILE__)))
VAGRANT = Vagrant::Environment.new(:cwd => VAGRANT_CONF, :ui_class => Vagrant::UI::Colored)

def run(command)
  begin
    VAGRANT.vms[:default].channel.sudo(command)
  rescue Exception => e
    puts "swallowed: #{e}"
  end
end
