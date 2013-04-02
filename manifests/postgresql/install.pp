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
class osiam::postgresql::install {
    if $osiam::ensure == 'present' {
        exec { 'installpostgresrepo':
            path    => '/bin:/usr/bin',
            command => "wget -O ${osiam::postgresql::repositorytmp} ${osiam::postgresql::repository} && \
                        yum install -y ${osiam::postgresql::repositorytmp} && \
                        rm -f ${osiam::postgresql::repositorytmp}",
            unless => "yum list installed pgdg-redhat92.noarch",
        }

        exec { 'postgresqlinitdb':
            command     => "/sbin/service ${osiam::postgresql::service} initdb",
            refreshonly => true,
        }

        Exec['installpostgresrepo'] -> Package[$osiam::postgresql::package] ~> Exec['postgresqlinitdb'] ->
        File["${osiam::postgresql::cpath}/postgresql.conf"] ->
        File["${osiam::postgresql::cpath}/pg_hba.conf"] -> Service[$osiam::postgresql::service]  

        File["${osiam::postgresql::cpath}/postgresql.conf"] ~> Service[$osiam::postgresql::service]
        File["${osiam::postgresql::cpath}/pg_hba.conf"] ~> Service[$osiam::postgresql::service]
    } else {
        File["${osiam::postgresql::cpath}/postgresql.conf"] ->
        File["${osiam::postgresql::cpath}/pg_hba.conf"] -> Service[$osiam::postgresql::service] ->
        Package[$osiam::postgresql::package]
    }

    package { $osiam::postgresql::package:
        ensure  => $osiam::ensure,
    }
    
    service { $osiam::postgresql::service:
        ensure  => $osiam::service_ensure,
        enable  => $osiam::service_enable,
        status  => '/bin/ps ax | /bin/grep postgres | /bin/grep -v grep',
    }
    
    file { "${osiam::postgresql::cpath}/postgresql.conf":
        ensure	=> $osiam::ensure,
        mode	=> '0644',
        owner	=> 'postgres',
        group	=> 'postgres',
        content	=> template('osiam/postgresql.conf.erb'),
    }
    
    file { "${osiam::postgresql::cpath}/pg_hba.conf":
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
