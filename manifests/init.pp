# Class: osiam
#
# This class deploys the osiam war(s) into an application server and installs a
# database schema for postgresql. It can also install and configure the
# application server (tomcat 7) and database (postgres 9.2).
#
# Parameters:
#  [*ensure*]           - Wether to install or remove osiam. Valid arguments are absent or present.
#  [*version*]          - Version of osiam artifacts to deploy.
#  [*dbuser*]           - postgresql database username
#  [*dbpassword*]       - postgresql database user password
#  [*dbname*]           - postgresql database name
#  [*dbhost*]           - postgresql database hostname
#  [*dbforceschema*]    - if set to 'true' all database tables will be dropped and redeployed if there
#  [*dbconnect*]        - An array of IPs that can connect to the database using md5 auth method.
#  [*installdb*]        - true (default) to install and configure postgresql 9.2
#  [*webappsdir*]       - Tomcat7 webapps directory path.
#  [*installas*]        - true (default) to install and configure tomcat 7
#  [*owner*]            - Artifact owner on filesystem.
#  [*group*]            - Artifact group on filesystem.
#  [*tomcatservice*]    - Name of the tomcat service (for restarts)
#  [*homedir*]          - Directory for osiam non-war files.
#  [*installjava*]      - true (default) to install java 1.7
#
# Actions:
#
#
# Requires:
#   maven installed
#   puppet-maven module
#   java 1.7
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
    $dbuser         = 'ong',
    $dbpassword     = 'ong',
    $dbname         = 'ong',
    $dbhost         = $::fqdn,
    $dbforceschema  = false,
    $dbconnect      = $::ipaddress,
    $installdb      = true,
    $ensure         = present,
    $webappsdir     = '/var/lib/tomcat7/webapps',
    $installas      = true,
    $owner          = 'tomcat',
    $group          = 'tomcat',
    $tomcatservice  = 'tomcat7',
    $homedir        = '/etc/osiam',
    $installjava    = true,
) {
    if $ensure == 'present' {
        $service_enable = true
        $service_ensure = running
        stage { 'osiam-prep': before => stage['main'], }
    } else {
        $service_enable = false
        $service_ensure = stopped
        stage { 'osiam-prep': require => stage['main'], }
    }

    if $installdb {
        class { 'osiam::postgresql':
            stage => 'osiam-prep',
        }
    }
    if $installas {
        class { 'osiam::tomcat::install':
            stage => 'osiam-prep',
        }
        class { 'osiam::tomcat::config': }
    }

    file { $homedir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
    }

    war { 'authorization-server':
        ensure  => $ensure,
        version => $version,
        path    => $webappsdir,
        owner   => $owner,
        group   => $group,
    }
    war { 'oauth2-client':
        ensure  => $ensure,
        version => $version,
        path    => $webappsdir,
        owner   => $owner,
        group   => $group,
    }
    class { 'osiam::database': }
}
