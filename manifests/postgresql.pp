class osiam::postgresql {
    $package        = 'postgresql92-server'
    $service        = 'postgresql-9.2'
    $cpath          = '/var/lib/pgsql/9.2/data'
    $rpm            = 'pgdg-redhat92-9.2-7.noarch.rpm'
    $repository     = "http://yum.postgresql.org/9.2/redhat/rhel-${::lsbmajdistrelease}-x86_64/${rpm}"
    $repositorytmp  = "/tmp/${rpm}"

    $listenaddresses    = '0.0.0.0'
    $port               = '5432'

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
    class osiam::postgresql::user {
        exec { "createrole_${osiam::dbuser}":
            command =>  "/usr/bin/psql -U postgres -c \
                        \"CREATE USER ${osiam::dbuser} WITH PASSWORD '${osiam::dbpassword}';\"",
            unless  => "/usr/bin/psql -U postgres -c \
                        \"SELECT * FROM pg_roles WHERE rolname='${osiam::dbuser}';\" \
                        | /bin/grep ${osiam::dbuser};",
            require => Service[$osiam::postgresql::service],
        }
    }
    class osiam::postgresql::database {
        exec { "createdatabase_$osiam::dbname":
            command => "/usr/bin/psql -U postgres -c \
                        \"CREATE DATABASE ${osiam::dbname} WITH OWNER ${osiam::dbuser};\"",
            unless	=> "/usr/bin/psql -U postgres -c \
                        \"SELECT * FROM pg_database WHERE datname='${osiam::dbname}';\" | \
                        /bin/grep ${osiam::dbname}",
            require	=> [
                Exec["createrole_${osiam::dbuser}"],
                Service[$osiam::postgresql::service],
            ],
        }
        exec { "alterdatabase_${osiam::dbname}":
            command	=>  "/usr/bin/psql -U postgres -c \
                        \"ALTER DATABASE ${osiam::dbname} OWNER TO ${osiam::dbuser};\"",
            unless	=>  "/usr/bin/psql -U postgres -c \
                        \"SELECT * from pg_database,pg_roles \
                            WHERE pg_database.datdba=pg_roles.oid \
                            AND pg_database.datname = '${osiam::dbname}' \
                            AND pg_roles.rolname='${osiam::dbuser}';\" | \
                        /bin/grep ${osiam::dbname}",
            require	=> [
                Exec["createdatabase_${osiam::dbname}"],
                Exec["createrole_${osiam::dbuser}"],
                Service[$osiam::postgresql::service],
            ],
        }
    }

    if ( $::operatingsystem == 'CentOS' ) or ( $::lsbmajdistrelease == '6') {
        class { 'osiam::postgresql::install': }->
        class { 'osiam::postgresql::user': }->
        class { 'osiam::postgresql::database': }
    } else {
        fail('Unsupported Operatingsystem')
    }

}
