# Class: osiam::postgresql::database
#
# This class creates a database. The owner of this database is the user created with
# osiam::postgresl::user.
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
#   class { 'osiam::postgresql::database': }
#
# Authors:
#   Kevin Viola Schmitz <k.schmitz@tarent.de>
#
class osiam::postgresql::database {
    exec { "createdatabase_$osiam::dbname":
        command => "/usr/bin/psql -U postgres -c \
                    \"CREATE DATABASE ${osiam::dbname} WITH OWNER ${osiam::dbuser};\"",
        unless	=> "/usr/bin/psql -U postgres -c \
                    \"SELECT * FROM pg_database WHERE datname='${osiam::dbname}';\" | \
                    /bin/grep ${osiam::dbname}",
        require	=> [
            Exec["createrole_${osiam::dbuser}"],
            Service[$osiam::postgresql::service],
        ],
    }
    exec { "alterdatabase_${osiam::dbname}":
        command	=>  "/usr/bin/psql -U postgres -c \
                    \"ALTER DATABASE ${osiam::dbname} OWNER TO ${osiam::dbuser};\"",
        unless	=>  "/usr/bin/psql -U postgres -c \
                    \"SELECT * from pg_database,pg_roles \
                        WHERE pg_database.datdba=pg_roles.oid \
                        AND pg_database.datname = '${osiam::dbname}' \
                        AND pg_roles.rolname='${osiam::dbuser}';\" | \
                    /bin/grep ${osiam::dbname}",
        require	=> [
            Exec["createdatabase_${osiam::dbname}"],
            Exec["createrole_${osiam::dbuser}"],
            Service[$osiam::postgresql::service],
        ],
    }
}
