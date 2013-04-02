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
    if ( $::operatingsystem == 'CentOS' ) or ( $::lsbmajdistrelease == '6') {
        file { '/etc/yum.repos.d/jpackage.repo':
            ensure => $osiam::ensure,
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => 'puppet:///modules/osiam/jpackage.repo',
        }

        if $osiam::ensure == 'present' {
            exec { 'jpackage-repo-yumcleanall':
                path        => '/usr/bin',
                command     => 'yum clean all',
                refreshonly => true,
                before      => Package['tomcat7'],
                subscribe   => File['/etc/yum.repos.d/jpackage.repo'],
            }

            exec { 'jpackage-gpg':
                path        => '/bin',
                command     => 'rpm --import http://www.jpackage.org/jpackage.asc',
                refreshonly => true,
                before      => Package['tomcat7'],
                subscribe   => File['/etc/yum.repos.d/jpackage.repo'],
            }
        }

        package { 'tomcat7':
            ensure => $osiam::ensure,
        }

        firewall { '099 tomcat':
            action => accept,
            dport  => '8080',
            proto  => 'tcp',
        }
    }
}
