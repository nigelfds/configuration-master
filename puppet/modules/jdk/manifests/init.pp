class jdk {
  package { "oracle-jdk":
    ensure => "installed",
    source => "http://dl.dropbox.com/u/58853148/jdk-7u3-linux-i586.rpm",
    provider => "rpm",
  }
}
