class osiam::postgresql::install {
    exec { 'installpostgresrepo':
        path    => '/bin:/usr/bin',
        command => "wget -O ${osiam::postgresql::repositorytmp} ${osiam::postgresql::repository} && \
                    yum install -y ${osiam::postgresql::repositorytmp} && \
                    rm -f ${osiam::postgresql::repositorytmp}",
        unless  => "yum list installed pgdg-redhat92.noarch",
    }

    package { $osiam::postgresql::package:
        ensure  => installed,
        require => Exec['installpostgresrepo'],
        notify  => Exec['postgresqlinitdb'],
    }

    exec { 'postgresqlinitdb':
        command     => "/sbin/service ${osiam::postgresql::service} initdb",
        refreshonly => true,
        before      => Service[$osiam::postgresql::service],
    }
    
    service { $osiam::postgresql::service:
        ensure  => running,
        enable  => true,
        status  => '/bin/ps ax | /bin/grep postgres | /bin/grep -v grep',
        require => Package[$osiam::postgresql::package],
    }
    
    file { "${osiam::postgresql::cpath}/postgresql.conf":
        ensure	=> present,
        mode	=> '0644',
        owner	=> 'postgres',
        group	=> 'postgres',
        content	=> template('osiam/postgresql.conf.erb'),
        notify	=> Service[$osiam::postgresql::service],
        require	=> Exec['postgresqlinitdb'],
    }
    
    file { "${osiam::postgresql::cpath}/pg_hba.conf":
        ensure	=> present,
        mode    => '0644',
        owner   => 'postgres',
        group   => 'postgres',
        content => template('osiam/pg_hba.conf.erb'),
        notify	=> Service["$osiam::postgresql::service"],
        require	=> Exec['postgresqlinitdb'],
    }
    
    firewall { '100 postgresql':
        action  => accept,
        dport   => '5432',
        proto   => 'tcp',
    }
}
