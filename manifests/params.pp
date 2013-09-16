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

            $java_package       = 'java-1.7.0-openjdk'
            $tomcat_package     = 'tomcat7'
            $tomcat_service     = 'tomcat7'
            $tomcat_conf_path   = '/usr/share/tomcat7/conf'
            $tomcat_owner       = 'tomcat'
            $tomcat_group       = 'tomcat'
            $tomcat_storePass   = 'changeit'
            $tomcat_keyPass     = 'changeit'
        }
        'Debian': {
            $package            = 'postgresql'
            $service            = 'postgresql'
            $cpath              = '/etc/postgresql/9.1/main'
            $repositorytmp      = "/tmp/${rpm}"
            $listenaddresses    = '0.0.0.0'
            $port               = '5432'

            $java_package       = 'openjdk-7-jdk'
            $tomcat_package     = 'tomcat7'
            $tomcat_service     = 'tomcat7'
            $tomcat_conf_path   = '/var/lib/tomcat7/conf'
            $tomcat_owner       = 'tomcat7'
            $tomcat_group       = 'tomcat7'
            $tomcat_storePass   = 'changeit'
            $tomcat_keyPass     = 'changeit'
        }
        default: {
            fail("Unsupported operatingsystem: ${::operatingsystem}")
        }
    }
}
