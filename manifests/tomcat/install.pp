# Class: osiam::tomcat::install
#
# This class installs tomcat 7 on a CentOS 6 system. It is installed from the jpackage repository. A basic
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
class osiam::tomcat::install {
    if ( $::operatingsystem == 'CentOS' ) and ( $::lsbmajdistrelease == '6') {

        if $osiam::installjava {
            package { 'java-1.7.0-openjdk':
                ensure => $osiam::ensure,
                before => Package['tomcat7'],
            }
        }

        package { 'tomcat7':
            ensure  => $osiam::ensure,
            require => Class['osiam::jpackage'],
        }

        firewall { '099 tomcat':
            action => accept,
            dport  => '8080',
            proto  => 'tcp',
        }
    }
}
