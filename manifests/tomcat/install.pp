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
class osiam::tomcat::install inherits osiam::params {
    if $osiam::installjava {
        package { $osiam::params::java_package:
            ensure => $osiam::ensure,
            before => Package[$osiam::params::tomcat_package],
        }
    }

    package { $osiam::params::tomcat_package:
        ensure  => $osiam::ensure,
    }

    firewall { '099 tomcat':
        action => accept,
        dport  => '8080',
        proto  => 'tcp',
    }
}
