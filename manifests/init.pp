# Class: osiam
#
# This class deploys the osiam war(s) into an existinc application server.
#
# Parameters:
#   [*ensure*]      - Wether to install or remove osiam. Valid arguments are absent or present.
#   [*version*]     - Version of osiam artifacts to deploy.
#   [*webappsdir]   - Tomcat7 webapps directory path.
#   [*owner*]       - Artifact owner on filesystem.
#   [*group*]       - Artifact group on filesystem.
#
# Actions:
#
#
# Requires:
#   maven installed
#   puppet-maven module
#   java 1.7
#   tomcat 7
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
    $ensure,
    $version,  
    $webappsdir,
    $owner          = 'tomcat',
    $group          = 'tomcat',
) {
    osiam::artifact { 'authorization-server': }
    osiam::artifact { 'oauth2-client': }
}
