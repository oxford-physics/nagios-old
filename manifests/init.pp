#class nagios-nrpe
class nagios::nrpe {
#sean



###http://projects.puppetlabs.com/projects/1/wiki/Nagios_Patterns
  case $operatingsystem {
    "freebsd": {
      $nrpeservice = "nrpe2"
      $nrpepattern = "nrpe2"
      $nrpepackage = "nrpe2"
      $nrpedir     = "/usr/local/etc"
      $nagiosuser  = "root"
      $nagiosgroup = "wheel"
      $pluginsdir  = "/usr/local/libexec/nagios"
      $sudopath    = "/usr/local/bin"
      $pluginspackage  = "nagios-plugins"
    }
    "Scientific": {
      $nrpeservice = "nrpe"
      $nrpepattern = "nrpe"
      $nrpepackage = "nrpe"
      $nrpedir     = "/etc/nagios"
      $nagiosuser  = "nagios"
      $nagiosgroup = "nagios"
      $pluginsdir  = "/usr/lib64/nagios/plugins"
      $sudopath    = "/usr/bin"
      $pluginspackage  = "nagios-plugins-nrpe"
      ensure_packages ( ["nagios-plugins-load", "nagios-plugins-disk", "nagios-plugins-users"] )
    }
    default: {
      $nrpeservice = "nagios-nrpe-server"
      $nrpepattern = "nrpe"
      $nrpepackage = "nagios-nrpe-server"
      $nrpedir     = "/etc/nagios"
      $nagiosuser  = "nagios"
      $nagiosgroup = "nagios"
      $pluginsdir  = "/usr/lib/nagios/plugins"
      $sudopath    = "/usr/bin"
      $pluginspackage  = "nagios-plugins"
    }
  }

  file { $pluginsdir:
    mode    => "755",
    require => Package["$pluginspackage"],
### SCB ###
#    source  => "puppet:///nagios/client-plugins/",
    source  => "puppet:///${site_files}/nagios/client-plugins/",
    purge   => false,
    recurse => true,
  }

  file { "$nrpedir/nrpe.cfg":
    mode    => "644",
    owner   => $nagiosuser,
    group   => $nagiosgroup,
    content => template("nagios/nrpe.cfg"),
    require => Package[$nrpepackage],
  }

  package {
    $nrpepackage: ensure => present;
    $pluginspackage : ensure => present;
  }

  service { "$nrpeservice":
    ensure    => running,
    enable    => true,
    pattern   => "$nrpepattern",
    subscribe => File["$nrpedir/nrpe.cfg"];
  }
}

class nagios-server {

  file { "/var/log/nagios2/rw":
    ensure  => directory,
    owner   => "nagios",
    group   => "www-data",
    require => [ Package["nagios2"], Package["apache2"] ],
    mode    => "2770",
  }

  file { "/usr/lib/nagios/plugins/check_dhcp":
    mode => "4755",
  }

  file { "/etc/nagios2":
    mode    => "644",
    source  => "puppet:///nagios/nagios",
    recurse => true,
    purge   => true,
    force   => true,
    ignore  => [ ".svn", "nrpe.cfg" ],
    require => Package["nagios2"],
  }

  file { "/usr/share/nagios2/htdocs/images/logos":
    mode    => "644",
    source  => "puppet:///nagios/logos",
    recurse => true,
    purge   => false,
    require => Package["nagios2"],
  }

  file { "/etc/default/nagios2":
    mode    => "644",
    source  => "puppet:///nagios/default.$hostname",
    require => Package["nagios2"],
  }

  user { "www-data":
    ensure     => present,
    groups     => "nagios",
    membership => minimum,
    require    => [ Package["nagios2"], Package["apache2"] ],
  }

  package {
    "nagios-nrpe-plugin":              ensure => present;
    "nagios2":                         ensure => present;
    "nagios2-common":                  ensure => present;
    "nagios2-doc":                     ensure => present;
  }

  service { "nagios2":
    ensure     => running,
    enable     => true,
    hasrestart => true,
    subscribe  => [ File["/etc/nagios2"], File["/etc/default/nagios2"] ],
  }

}
