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
class osiam::tomcat::config {
    if ( $::operatingsystem == 'CentOS' ) or ( $::lsbmajdistrelease == '6') {
        $shared_loader = $osiam::homedir
        file { 'catalina.properties':
            path    => '/usr/share/tomcat7/conf/catalina.properties',
            ensure  => $osiam::ensure,
            content => template('osiam/catalina.properties.erb'),
            require => Class['osiam::tomcat::install'],
            notify  => Service['tomcat7'],
        }
        service { 'tomcat7':
            ensure  => $osiam::service_ensure,
            enable  => $osiam::service_enable,
            require => Class['osiam::tomcat::install'],
        }
    }
}
