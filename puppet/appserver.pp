class appserver {
  package { "aws-twitter-feed":
    provider => "rpm",
    source   => "${artifact}",
    ensure   => "installed",
  }
}
include appserver
