class go::server {
  package { "newrelic-repo":
    ensure => "installed",
    source => "http://download.newrelic.com/pub/newrelic/el5/i386/newrelic-repo-5-3.noarch.rpm",
    provider => "rpm",
  }

  package { "newrelic-sysmond":
    ensure => "installed",
    require => Package["newrelic-repo"],
  }

  exec { "/usr/sbin/nrsysmond-config --set license_key=33bc054596d2e8c21ad5aa0afe4d570338bd7d63":
    require => Package["newrelic-sysmond"],
  }

  service { "newrelic-sysmond": ensure => "running" }

  package { ["rpm-build", "git", "unzip"]: ensure => "installed" }

  package { "oracle-jdk":
    ensure => "installed",
    source => "http://dl.dropbox.com/u/58853148/jdk-7u3-linux-i586.rpm",
    provider => "rpm",
  }

  package { "go-server":
    ensure => "installed",
    source => "http://download01.thoughtworks.com/go/12.2.1/ga/go-server-12.2.1-15143.noarch.rpm",
    provider => "rpm",
    require => [Package["oracle-jdk"], Package["unzip"]],
  }

  service { "go-server":
    ensure => "running",
    subscribe => File["/etc/go/cruise-config.xml"],
    require => Package["go-server"],
  }

  file { "/etc/go/cruise-config.xml":
    ensure => "present",
    owner  => "go",
    group  => "go",
    source => "${work_dir}/modules/go-server/files/cruise-config.xml",
    require => Package["go-server"],
  }

  package { "go-agent":
    ensure => "installed",
    source => "http://download01.thoughtworks.com/go/12.2.1/ga/go-agent-12.2.1-15143.noarch.rpm",
    provider => "rpm",
    require => Package["oracle-jdk"],
  }

  service { "go-agent":
    ensure => "running",
    require => Package["go-agent"],
  }
}

include go::server
