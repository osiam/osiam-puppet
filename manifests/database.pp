# Class: osiam::database
#
# This class handles database initialization, actualization and cleanup. It will check for a specific
# database table. If that table is missing this class will unzip an initialization script from the
# osiam-server.war file and execute it.
#
# Requires:
#   postgresql 9.2 installed
#
# Actions:
#
#
# Sample usage:
#   class { 'osiam::database': }
#
class osiam::database {
    file { 'db-config.properties':
        ensure  => $osiam::ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        path    => "${osiam::homedir}/db-config.properties",
        content => template('osiam/db-config.properties.erb'),
        notify  => Service[$osiam::tomcatservice],
        require => File[$osiam::homedir],
    }

    case $osiam::ensure {
        present: {
            # Check if there is a new init.sql script inside the osiam-server.war and
            # extract it to ${osiam::homedir}/install-schema.sql
            exec { 'extract-install-schema':
                path    => '/usr/bin',
                command => "unzip -p ${osiam::webappsdir}/osiam-server.war \
                            WEB-INF/classes/sql/init.sql > ${osiam::homedir}/install-schema.sql",
                unless  => "unzip -p ${osiam::webappsdir}/osiam-server.war \
                            WEB-INF/classes/sql/init.sql > /tmp/init.sql && \
                            test \"$(md5sum /tmp/init.sql | awk '{print \$1}')\" = \
                            \"$(md5sum ${osiam::homedir}/install-schema.sql | awk '{print \$1}')\"",
                require => [
                                File[$osiam::homedir],
                                War['osiam-server'],
                           ],
            }
            # Check if there is a new drop.sql script inside the osiam-server.war and
            # extract it to ${osiam::homedir}/remove-schema.sql
            exec { 'extract-remove-schema':
                path    => '/usr/bin',
                command => "unzip -p ${osiam::webappsdir}/osiam-server.war \
                            WEB-INF/classes/sql/drop.sql > ${osiam::homedir}/remove-schema.sql",
                unless  => "unzip -p ${osiam::webappsdir}/osiam-server.war \
                            WEB-INF/classes/sql/drop.sql > /tmp/drop.sql && \
                            test \"$(md5sum /tmp/drop.sql | awk '{print \$1}')\" = \
                            \"$(md5sum ${osiam::homedir}/remove-schema.sql | awk '{print \$1}')\"",
                require => [
                                File[$osiam::homedir],
                                War['osiam-server'],
                           ],
            }

            if $osiam::dbforceschema {
                # If install-schema.sql was modified through extract-install-schema (there is a new
                # version) then dump remove-schema.sql and afterwards install-schema.sql
                exec { 'force-schema':
                    path        => '/usr/bin',
                    environment => "PGPASSWORD=${osiam::dbpassword}",
                    command     => "psql -h ${osiam::dbhost} -U ${osiam::dbuser} -d ${osiam::dbname} -w \
                                    < ${osiam::homedir}/remove-schema.sql && \
                                    psql -h ${osiam::dbhost} -U ${osiam::dbuser} -d ${osiam::dbname} -w \
                                    < ${osiam::homedir}/install-schema.sql",
                    refreshonly => true,
                    subscribe   => Exec["extract-install-schema"],
                    before      => Exec['install-schema'],
                    notify      => Service[$osiam::tomcatservice],
                }
            }
            # Check if table scim_meta existsi and dump install-schema.sql if it's missing
            exec { 'install-schema':
                path        => '/usr/bin',
                environment => "PGPASSWORD=${osiam::dbpassword}",
                command     => "psql -h ${osiam::dbhost} -U ${osiam::dbuser} -d ${osiam::dbname} -w < \
                                ${osiam::homedir}/install-schema.sql",
                unless      => "psql -h ${osiam::dbhost} -U ${osiam::dbuser} -d ${osiam::dbname} -w -c \
                                'select * from scim_meta'",
                require     => Exec["extract-install-schema"],
                notify      => Service[$osiam::tomcatservice],
            }
        }
        absent: {
            exec { 'remove-schema':
                path        => '/usr/bin',
                environment => "PGPASSWORD=${osiam::dbpassword}",
                command     => "psql -h ${osiam::dbhost} -U ${osiam::dbuser} -d ${osiam::dbname} -w < \
                                ${osiam::homedir}/remove-schema.sql",
                onlyif      => "psql -h ${osiam::dbhost} -U ${osiam::dbuser} -d ${osiam::dbname} -w -c \
                                'select * from scim_meta' && \
                                test -s ${osiam::homedir}/remove-schema.sql",
            }
        }
        default: {
            fail("Please set ensure to either 'present' or 'absent'")
        }
    }
}
