#!/bin/bash -e

export BUNDLE_GEMFILE="$(pwd)/conf/Gemfile"
export RAKEFILE="$(pwd)/lib/rakefile.rb"

# ensure RVM is installed
if [ ! -d "$HOME/.rvm" ]; then
  echo "installing rvm..."
  curl -L get.rvm.io | bash -s stable
fi

source ~/.rvm/scripts/'rvm'
rvm rvmrc trust
rvm rvmrc load .

# install gems using bundler
gem list | grep bundler  || gem install bundler --version 1.0.21 --no-rdoc --no-ri
bundle check || bundle install

bundle exec rake -f $RAKEFILE $@

