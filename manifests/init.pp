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
    $id             = undef,
    $ensure         = present,
    $homedir        = '/etc/osiam',
    $installdb      = true,
    $dbuser         = 'ong',
    $dbpassword     = 'ong',
    $dbname         = 'ong',
    $dbhost         = $::fqdn,
    $dbforceschema  = false,
    $dbconnect      = $::ipaddress,
    $installas      = true,
    $webappsdir     = '/var/lib/tomcat7/webapps',
    $owner          = $osiam::params::tomcat_owner,
    $group          = $osiam::params::tomcat_group,
    $forcessl       = false,
    $tomcatservice  = 'tomcat7',
    $installjava    = true,
    $installmaven   = true,
    $client_tag     = 'osiam-client',
) {
    class install {
        if $osiam::installdb {
            class { 'osiam::postgresql::install': }
            class { 'osiam::postgresql::user': }
            class { 'osiam::postgresql::database': }
        }

        if ( $osiam::installmaven ) or ( $osiam::installas ) {
            class { 'osiam::jpackage': }
        }

        if $osiam::installmaven {
            class { 'osiam::maven::install': }
        }

        if $osiam::installas {
            class { 'osiam::tomcat::install': }
        }
    }
    class config {
        if $osiam::installas {
            class { 'osiam::tomcat::config': }
        }
    }
    class deploy {
        file { $osiam::homedir:
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0744',
        }

        file { 'osiam.properties':
            ensure  => $osiam::ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0744',
            path    => "${osiam::homedir}/osiam.properties",
            content => template('osiam/osiam.properties.erb'),
            notify  => Service[$osiam::tomcatservice],
            require => File[$osiam::homedir],
        }

        war { 'osiam-auth-server':
            ensure  => $osiam::ensure,
            version => $osiam::version,
            id      => $osiam::id,
            path    => $osiam::webappsdir,
            owner   => $osiam::owner,
            group   => $osiam::group,
            require => File['osiam.properties'],
        }

        war { 'osiam-resource-server':
            ensure  => $osiam::ensure,
            version => $osiam::version,
            id      => $osiam::id,
            path    => $osiam::webappsdir,
            owner   => $osiam::owner,
            group   => $osiam::group,
            require => File['osiam.properties'],
        }

        # Note: only the resource server connects to the database
        dbschema { 'osiam-resource-server':
            ensure        => $osiam::ensure,
            artifactpath  => $osiam::webappsdir,
            osiampath     => $osiam::homedir,
            dbhost        => $osiam::dbhost,
            dbname        => $osiam::dbname,
            dbuser        => $osiam::dbuser,
            dbpassword    => $osiam::dbpassword,
            dbforceschema => $osiam::dbforceschema,
            require       => War['osiam-resource-server'],
        }

        $dbconnection = {
            host     => $osiam::dbhost,
            name     => $osiam::dbname,
            user     => $osiam::dbuser,
            password => $osiam::dbpassword,
        }

        Osiamclient <<| tag == "${osiam::client_tag}" |>> {
            dbconnection => $dbconnection,
            require      => Dbschema['osiam-resource-server'],
            notify       => Service[$osiam::tomcatservice],
        }

    }

    if $ensure == 'present' {
        $service_enable = true
        $service_ensure = running
        stage { 'install': before => Stage['main'], }
    } else {
        $service_enable = false
        $service_ensure = stopped
        stage { 'install': require => Stage['main'], }
    }

    class { 'install':
        stage => 'install',
    }
    class { 'config':
        stage => 'main',
    }
    class { 'deploy':
        stage => 'main',
    }
}
