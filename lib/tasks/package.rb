namespace :package do
  task :puppet do
    mkdir_p "#{BUILD_DIR}/package"
    cp_r "puppet", "#{BUILD_DIR}/package/puppet"
    cp("conf/settings.yaml", "#{BUILD_DIR}/package/puppet") unless (ENV["GO_SERVER_URL"] || ENV["SETTINGS_FILE"]
    sh "cd #{BUILD_DIR}/package; tar -zcf ../#{BOOTSTRAP_FILE} *"
  end
end
