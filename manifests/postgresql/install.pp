# Class: osiam::postgresql::install
#
# This class installs postgresql 9.2 by first installing the postgres repository. It then does a database
# initialization and sets up basic firewall rule.
#
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
#   class { 'osiam::postgresql::install': }
#
# Authors:
#   Kevin Viola Schmitz <k.schmitz@tarent.de>
#
class osiam::postgresql::install inherits osiam::params {
    if $osiam::ensure == 'present' {
        if $::operatingsystem == 'CentOS' {
            exec { 'installpostgresrepo':
                path    => '/bin:/usr/bin',
                command => "wget -O ${osiam::params::repositorytmp} ${osiam::params::repository} && \
                            yum install -y ${osiam::params::repositorytmp} && \
                            rm -f ${osiam::params::repositorytmp}",
                unless => "yum list installed pgdg-redhat92.noarch",
                before => Package[$osiam::params::package],
            }

            exec { 'postgresqlinitdb':
                command     => "/sbin/service ${osiam::params::service} initdb",
                refreshonly => true,
                subscribe   => Package[$osiam::params::package],
                before      => File["${osiam::params::cpath}/postgresql.conf"],
            }
        }

        Package[$osiam::params::package] -> File["${osiam::params::cpath}/postgresql.conf"] ->
        File["${osiam::params::cpath}/pg_hba.conf"] -> Service[$osiam::params::service]  

        File["${osiam::params::cpath}/postgresql.conf"] ~> Service[$osiam::params::service]
        File["${osiam::params::cpath}/pg_hba.conf"] ~> Service[$osiam::params::service]
    } else {
        File["${osiam::params::cpath}/postgresql.conf"] ->
        File["${osiam::params::cpath}/pg_hba.conf"] -> Service[$osiam::params::service] ->
        Package[$osiam::params::package]
    }

    package { $osiam::params::package:
        ensure  => $osiam::ensure,
    }
    
    service { $osiam::params::service:
        ensure  => $osiam::service_ensure,
        enable  => $osiam::service_enable,
        status  => '/bin/ps ax | /bin/grep postgres | /bin/grep -v grep',
    }
    
    file { "${osiam::params::cpath}/postgresql.conf":
        ensure	=> $osiam::ensure,
        mode	=> '0644',
        owner	=> 'postgres',
        group	=> 'postgres',
        content	=> template('osiam/postgresql.conf.erb'),
    }
    
    file { "${osiam::params::cpath}/pg_hba.conf":
        ensure	=> $osiam::ensure,
        mode    => '0644',
        owner   => 'postgres',
        group   => 'postgres',
        content => template('osiam/pg_hba.conf.erb'),
    }
    
    firewall { '100 postgresql':
        action  => accept,
        dport   => '5432',
        proto   => 'tcp',
    }
}
