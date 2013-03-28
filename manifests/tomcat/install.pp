class osiam::tomcat::install {
    if ( $::operatingsystem == 'CentOS' ) or ( $::lsbmajdistrelease == '6') {
        file { '/etc/yum.repos.d/jpackage.repo':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => 'puppet:///modules/osiam/jpackage.repo',
            notify => [
                Exec['jpackage-repo-yumcleanall'],
                Exec['jpackage-gpg'],
            ],
        }

        exec { 'jpackage-repo-yumcleanall':
            path        => '/usr/bin',
            command     => 'yum clean all',
            refreshonly => true,
            require     => File['/etc/yum.repos.d/jpackage.repo'],
        }

        exec { 'jpackage-gpg':
            path        => '/bin',
            command     => 'rpm --import http://www.jpackage.org/jpackage.asc',
            refreshonly => true,
            require     => File['/etc/yum.repos.d/jpackage.repo'],
        }

        package { 'tomcat7':
            ensure  => present,
            require => [
                Exec['jpackage-repo-yumcleanall'],
                Exec['jpackage-gpg'],
            ],
        }

        firewall { '099 tomcat':
            action => accept,
            dport  => '8080',
            proto  => 'tcp',
        }
    }
}
