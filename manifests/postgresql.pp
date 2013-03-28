class osiam::postgresql {
    $package        = 'postgresql92-server'
    $service        = 'postgresql-9.2'
    $cpath          = '/var/lib/pgsql/9.2/data'
    $rpm            = 'pgdg-redhat92-9.2-7.noarch.rpm'
    $repository     = "http://yum.postgresql.org/9.2/redhat/rhel-${::lsbmajdistrelease}-x86_64/${rpm}"
    $repositorytmp  = "/tmp/${rpm}"

    if ( $::operatingsystem == 'CentOS' ) or ( $::lsbmajdistrelease == '6') {
        exec { 'installpostgresrepo':
            path    => '/bin:/usr/bin',
            command => "wget -O ${repositorytmp} ${repository} && \
                        yum install -y ${repositorytmp} && \
                        rm -f ${repositorytmp}",
            unless  => "yum list installed ${rpm}",
        }

        package { $package:
            ensure  => installed,
            require => Exec['installpostgresrepo'],
            notify  => Exec['postgresqlinitdb'],
        }

        exec { 'postgresqlinitdb':
            command     => "/sbin/service ${service} initdb",
            refreshonly => true,
            before      => Service[$service],
        }
        
        service { $service
            ensure  => running,
            enable  => true,
            status  => '/bin/ps ax | /bin/grep postgres | /bin/grep -v grep',
            require => Package[$package],
        }
        
        file { "${cpath}/postgresql.conf":
            ensure	=> present,
            mode	=> '0644',
            owner	=> 'postgres',
            group	=> 'postgres',
            content	=> template('postgresql/postgresql.conf.erb'),
            notify	=> Service[$service],
            require	=> Exec['postgresqlinitdb'],
        }
        
        file { "${cpath}/pg_hba.conf":
            ensure	=> present,
            mode    => '0644',
            owner   => 'postgres',
            group   => 'postgres',
            content => template('postgresql/pg_hba.conf.erb'),
            notify	=> Service["$service"],
            require	=> Exec['postgresqlinitdb'],
        }
        
        firewall { '100 postgresql':
            action  => accept,
            dport   => '5432',
            proto   => 'tcp',
        }
    } else {
        fail('Unsupported Operatingsystem')
    }

}
