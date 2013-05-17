# Class: osiam::postgresql
#
# This is the central postgresql class. It invokes the installation, user and database creation
# classes. Fails if the operating system isn't CentOS 6.
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
#   class { 'osiam::postgresql': }
#
# Authors:
#   Kevin Viola Schmitz <k.schmitz@tarent.de>
#
class osiam::params {
    case $::operatingsystem {
        'CentOS': {
            $package            = 'postgresql92-server'
            $service            = 'postgresql-9.2'
            $cpath              = '/var/lib/pgsql/9.2/data'
            $rpm                = 'pgdg-redhat92-9.2-7.noarch.rpm'
            $repository         = "http://yum.postgresql.org/9.2/redhat/rhel-${::lsbmajdistrelease}-x86_64/${rpm}"
            $repositorytmp      = "/tmp/${rpm}"
            $listenaddresses    = '0.0.0.0'
            $port               = '5432'
        }
        default: {
            fail("Unsupported operatingsystem: ${::operatingsystem}")
        }
    }
    
    
}
