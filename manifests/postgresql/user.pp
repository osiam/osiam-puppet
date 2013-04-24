# Class: osiam::postgresql::user
#
# This class creates a database user.
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
#   class { 'osiam::postgresql::user': }
#
# Authors:
#   Kevin Viola Schmitz <k.schmitz@tarent.de>
#
class osiam::postgresql::user inherits osiam::params {
    if $osiam::ensure == 'present' {
        exec { "createrole_${osiam::dbuser}":
            command =>  "/usr/bin/psql -U postgres -c \
                        \"CREATE USER ${osiam::dbuser} WITH PASSWORD '${osiam::dbpassword}';\"",
            unless  => "/usr/bin/psql -U postgres -c \
                        \"SELECT * FROM pg_roles WHERE rolname='${osiam::dbuser}';\" \
                        | /bin/grep ${osiam::dbuser};",
            require => Class['osiam::postgresql::install'],
        }

    } else {
        exec { "droprole_${osiam::dbuser}":
            command => "/usr/bin/psql -U postgres -c \"DROP ROLE ${osiam::dbuser};\"",
            onlyif  => "/usr/bin/psql -U postgres -c \
                        \"SELECT * FROM pg_roles WHERE rolname='${osiam::dbuser}';\" | \
                        /bin/grep ${osiam::dbuser};",
            before => Class['osiam::postgresql::install'],
        }
    }
}
