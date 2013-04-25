class osiam::jpackage {
    if ( $::operatingsystem == 'CentOS' ) and ( $::lsbmajdistrelease == '6') {
        file { '/etc/yum.repos.d/jpackage.repo':
            ensure => $osiam::ensure,
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => 'puppet:///modules/osiam/jpackage.repo',
        }

        if $osiam::ensure == 'present' {
            exec { 'jpackage-repo-yumcleanall':
                path        => '/usr/bin',
                command     => 'yum clean all',
                refreshonly => true,
                subscribe   => File['/etc/yum.repos.d/jpackage.repo'],
            }

            exec { 'jpackage-gpg':
                path        => '/bin',
                command     => 'rpm --import http://www.jpackage.org/jpackage.asc',
                refreshonly => true,
                subscribe   => File['/etc/yum.repos.d/jpackage.repo'],
            }
        }
    }
}
