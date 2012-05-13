namespace :test do
  task :puppet_syntax do
    sh "find . -name *.pp | xargs puppet parser validate"
    puts "puppet syntax check ok"
  end
end
