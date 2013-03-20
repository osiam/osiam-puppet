# Class: osiam
#
# This class deploys the osiam war(s) into an existing application server and installs a database
# schema for postgresql.
#
# Parameters:
#   [*ensure*]          - Wether to install or remove osiam. Valid arguments are absent or present.
#   [*version*]         - Version of osiam artifacts to deploy.
#   [*webappsdir]       - Tomcat7 webapps directory path.
#   [*owner*]           - Artifact owner on filesystem.
#   [*group*]           - Artifact group on filesystem.
#   [*homedir*]         - Directory for osiam non-war files.
#   [*dbhost*]          - postgresql database hostname
#   [*dbuser*]          - postgresql database username
#   [*dbpassword*]      - postgresql database user password
#   [*dbname*]          - postgresql database name
#   [*dbforceschema*]   - if set to 'true' all database tables will be dropped and redeployed if there
#                         are changes to the schema.
#
# Actions:
#
#
# Requires:
#   maven installed
#   puppet-maven module
#   java 1.7
#   tomcat 7
#   postgresql 9.2
#   unzip
#
# Sample Usage:
#   class { 'osiam':
#       ensure     => present,
#       version    => '0.2-SNAPSHOT'
#       webappsdir => '/var/lib/tomcat7/webapps'
#    }
#
# Authors:
#   Kevin Viola Schmitz <k.schmitz@tarent.de>
#
class osiam (
    $version,  
    $dbuser,
    $dbpassword,
    $dbname,
    $dbhost         = $::fqdn,
    $ensure         = present,
    $webappsdir     = '/var/lib/tomcat7/webapps',
    $owner          = 'tomcat',
    $group          = 'tomcat',
    $tomcatservice  = 'tomcat7',
    $homedir        = '/etc/osiam',
    $dbforceschema  = false,
) {
    osiam::artifact { 'authorization-server': }
    osiam::artifact { 'oauth2-client': }

    file { $homedir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }

    case $ensure {
        present: {
            # Check if there is a new init.sql script inside the authorization-server.war and
            # extract it to ${homedir}/install-schema.sql
            exec { 'extract-install-schema':
                path    => '/usr/bin',
                command => "unzip -p ${webappsdir}/authorization-server.war \
                            WEB-INF/classes/sql/init.sql > ${homedir}/install-schema.sql",
                unless  => "unzip -p ${webappsdir}/authorization-server.war \
                            WEB-INF/classes/sql/init.sql > /tmp/init.sql && \
                            test \"$(md5sum /tmp/init.sql | awk '{print \$1}')\" == \
                            \"$(md5sum ${homedir}/install-schema.sql | awk '{print \$1}')\"",
                require => [
                                File[$homedir],
                                Maven['authorization-server'],
                           ],
            }
            # Check if there is a new drop.sql script inside the authorization-server.war and
            # extract it to ${homedir}/remove-schema.sql
            exec { 'extract-remove-schema':
                path    => '/usr/bin',
                command => "unzip -p ${webappsdir}/authorization-server.war \
                            WEB-INF/classes/sql/drop.sql > ${homedir}/remove-schema.sql",
                unless  => "unzip -p ${webappsdir}/authorization-server.war \
                            WEB-INF/classes/sql/drop.sql > /tmp/drop.sql && \
                            test \"$(md5sum /tmp/drop.sql | awk '{print \$1}')\" == \
                            \"$(md5sum ${homedir}/remove-schema.sql | awk '{print \$1}')\"",
                require => [
                                File[$homedir],
                                Maven['authorization-server'],
                           ],
            }

            if $dbforceschema {
                # If install-schema.sql was modified through extract-install-schema (there is a new
                # version) then dump remove-schema.sql and afterwards install-schema.sql
                exec { 'force-schema':
                    path        => '/usr/bin',
                    environment => "PGPASSWORD=${dbpassword}",
                    command     => "psql -h ${dbhost} -U ${dbuser} -d ${dbname} -w < \
                                    ${homedir}/remove-schema.sql && \
                                    psql -h ${dbhost} -U ${dbuser} -d ${dbname} -w < \
                                    ${homedir}/install-schema.sql",
                    refreshonly => true,
                    subscribe   => Exec["extract-install-schema"],
                    before      => Exec['install-schema'],
                    notify      => Service[$tomcatservice],
                }
            }
            # Check if table scim_meta existsi and dump install-schema.sql if it's missing
            exec { 'install-schema':
                path        => '/usr/bin',
                environment => "PGPASSWORD=${dbpassword}",
                command     => "psql -h ${dbhost} -U ${dbuser} -d ${dbname} -w < \
                                ${homedir}/install-schema.sql",
                unless      => "psql -h ${dbhost} -U ${dbuser} -d ${dbname} -w -c \
                                'select * from scim_meta'",
                require     => Exec["extract-install-schema"],
                notify      => Service[$tomcatservice],
            }
        }
        absent: {
            exec { 'remove-schema':
                path        => '/usr/bin',
                environment => "PGPASSWORD=${dbpassword}",
                command     => "psql -h ${dbhost} -U ${dbuser} -d ${dbname} -w < \
                                ${homedir}/remove-schema.sql",
                onlyif      => "psql -h ${dbhost} -U ${dbuser} -d ${dbname} -w -c \
                                'select * from scim_meta' && \
                                test -s ${homedir}/remove-schema.sql",
            }
        }
        default: {
            fail("Please set ensure to either 'present' or 'absent'")
        }
    }
}
