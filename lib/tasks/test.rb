namespace :test do
  task :puppet_syntax do
    sh "find . -name *.pp | xargs puppet parser validate"
    puts "puppet syntax check ok"
  end

  namespace :twitter_feed do

    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new(:health_check) do |t|
      t.pattern = "spec/twitter_feed_app/**/*_spec.rb"
    end
  end

end
