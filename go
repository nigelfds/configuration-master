#!/bin/bash -e

BUNDLE_GEMFILE="$(pwd)/conf/Gemfile"
RAKEFILE="$(pwd)/lib/rakefile.rb"

# ensure RVM is installed
if [ ! -d "$HOME/.rvm" ]; then
  echo "installing rvm..."
  curl -L get.rvm.io | bash -s stable
fi

# load RVM and project config
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
rvm rvmrc trust . > /dev/null
source .rvmrc > /dev/null

# install gems using bundler
gem list | grep bundler  || gem install bundler --version 1.0.21 --no-rdoc --no-ri
bundle check || bundle install

bundle exec rake $@

