#!/bin/bash -e

BUNDLE_GEMFILE="$(pwd)/conf/Gemfile"
RAKEFILE="$(pwd)/lib/rakefile.rb"

function setup_rvm() {
  if [ ! -d "$HOME/.rvm" ]; then
    echo "installing rvm..."
    curl -L get.rvm.io | bash -s stable
  fi
  [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
}

function setup_bundler() {
  which bundle | grep rvm || {
    echo "installing bundler..."
    gem install bundler --no-rdoc --no-ri
  }
  export BUNDLE_GEMFILE
}

function setup_dependencies() {
  bundle check || bundle install
}

function run() {
  setup_rvm
  setup_bundler
  setup_dependencies
  bundle exec rake -f $RAKEFILE "$@"
}

run "$@"
