# Class: osiam::tomcat::config
#
# This class configures tomcat 7 on a CentOS 6 system.
# firewall rule is set up.
#
# Parameters:
#
# Actions:
#
# Requires:
#   maven installed
#   puppet-maven module
#   java 1.7
#   unzip
#
# Sample Usage:
#   class { 'osiam::tomcat::install': }
#
# Authors:
#   Kevin Viola Schmitz <k.schmitz@tarent.de>
#
class osiam::tomcat::config inherits osiam::params {
    $shared_loader = $osiam::homedir
    file { 'catalina.properties':
        path    => "${osiam::params::tomcat_conf_path}/catalina.properties",
        ensure  => $osiam::ensure,
        content => template('osiam/catalina.properties.erb'),
        require => Class['osiam::tomcat::install'],
        notify  => Service[$osiam::params::tomcat_service],
    }

    if $::operatingsystem == "Debian" {
        file { 'tomcat-init':
            path    => '/etc/init.d/tomcat7',
            ensure  => $osiam::ensure,
            source  => 'puppet:///modules/osiam/tomcat7',
            require => Class['osiam::tomcat::install'],
            notify  => Service[$osiam::params::tomcat_service],
        }
    }

    service { $osiam::params::tomcat_service:
        ensure  => $osiam::service_ensure,
        enable  => $osiam::service_enable,
        require => Class['osiam::tomcat::install'],
    }
}
