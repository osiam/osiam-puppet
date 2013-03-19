# Define: osiam
#
# This class is resposible for artifact deployment. It will check the deployed artifacts
# md5 sum with the latest md5sum from the osiam repository and redownload if necessary. Most variables
# are taken from class osiam.
#
# Parameters:
#   [*title*]   - Class title. This is used as artifact id
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
# Sample usage:
#   osiam::artifact { 'authorization-server': }
#
define osiam::artifact {
    case $osiam::ensure {
        present: {
            if $osiam::version =~ /.*-SNAPSHOT$/ {
                $repository = 'http://repo.osiam.org/snapshots'
                $path = "${repository}/org/osiam/ng/${name}/${osiam::version}"
                exec { "check${name}war":
                    path    => '/bin:/usr/bin',
                    command => "rm -rf ${osiam::webappsdir}/${name}{,.war}",
                    before  => Maven["${name}"],
                    unless  => "test \
                    \"$(curl -s ${path}/$(wget -O- ${path} 2>&1 | grep '.war' | grep '.md5' | \
                    sed -e 's/.*href=\"\\(.*md5\\)\">.*$/\1/' | sed 's/\\.\\.//' | tail -n 1))\" = \
                    \"$(md5sum ${osiam::webappsdir}/${name}.war | awk -F' ' '{ print \$1 }')\""
                }
            } else {
                $repository = 'http://repo.osiam.org/releases'
            }
            
            maven { $name:
                ensure     => present,
                path       => "${osiam::webappsdir}/${name}.war",
                groupid    => 'org.osiam.ng',
                artifactid => $name,
                version    => $osiam::version,
                packaging  => 'war',
                repos      => $repository,
                notify     => Exec["${name}permissions"],
            }
            exec { "${name}permissions":
                path        => '/bin',
                command     => "chown ${osiam::owner}:${osiam::group} ${osiam::webappsdir}/${name}.war",
                refreshonly => true,
            }
        }
        absent: {
            file { "${osiam::webappsdir}/${name}.war":
                ensure => absent,
                backup  => false,
            }
        }
        default: {
            fail("Ensure value not valid. Use 'present' or 'absent'.")
        }
    }
}
