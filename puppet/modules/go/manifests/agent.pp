class go::agent {
  package { ["rpm-build", "git"]: ensure => "installed" }

  package { "go-agent":
    ensure => "installed",
    source => "http://download01.thoughtworks.com/go/12.2.1/ga/go-agent-12.2.1-15143.noarch.rpm",
    provider => "rpm",
    require => Class["jdk"],
  }

  service { "go-agent":
    ensure => "running",
    require => Package["go-agent"],
  }
}
