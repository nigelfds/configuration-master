namespace :package do
  task :puppet do
    mkdir_p "#{BUILD_DIR}/package"
    cp_r "puppet", "#{BUILD_DIR}/package/puppet"
    sh "cd #{BUILD_DIR}/package; tar -zcf ../puppet.tar.gz *"
  end
end
