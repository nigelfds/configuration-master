class awstwitterfeed {
  package { "aws-twitter-feed":
    provider => "rpm",
    source   => "${artifact}",
    ensure   => "installed",
  }

  service { "aws-twitter-feed":
    ensure  => "running",
    require => Package["aws-twitter-feed"],
  }
}
