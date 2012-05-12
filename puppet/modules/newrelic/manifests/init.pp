class newrelic {
  package { "newrelic-repo":
    ensure => "installed",
    source => "http://download.newrelic.com/pub/newrelic/el5/i386/newrelic-repo-5-3.noarch.rpm",
    provider => "rpm",
  }

  package { "newrelic-sysmond":
    ensure => "installed",
    require => Package["newrelic-repo"],
  }

  exec { "config-newrelic":
    command => "/usr/sbin/nrsysmond-config --set license_key=33bc054596d2e8c21ad5aa0afe4d570338bd7d63",
    require => Package["newrelic-sysmond"],
  }

  service { "newrelic-sysmond": ensure => "running", require => Exec["config-newrelic"] }
}
