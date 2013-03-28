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
    $installdb      = true,
    $ensure         = present,
    $webappsdir     = '/var/lib/tomcat7/webapps',
    $owner          = 'tomcat',
    $group          = 'tomcat',
    $tomcatservice  = 'tomcat7',
    $homedir        = '/etc/osiam',
    $dbforceschema  = false,
) {
    file { $homedir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0744',
    }

    if $installdb {
        class { 'osiam::postgresql': }->
    }

    osiam::artifact { 'authorization-server': }
    osiam::artifact { 'oauth2-client': }
    class { 'osiam::database': }
}
