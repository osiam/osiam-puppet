class osiam::postgresql {
    $package            = 'postgresql92-server'
    $service            = 'postgresql-9.2'
    $cpath              = '/var/lib/pgsql/9.2/data'
    $rpm                = 'pgdg-redhat92-9.2-7.noarch.rpm'
    $repository         = "http://yum.postgresql.org/9.2/redhat/rhel-${::lsbmajdistrelease}-x86_64/${rpm}"
    $repositorytmp      = "/tmp/${rpm}"
    $listenaddresses    = '0.0.0.0'
    $port               = '5432'

    if ( $::operatingsystem == 'CentOS' ) or ( $::lsbmajdistrelease == '6') {
        class { 'osiam::postgresql::install': }->
        class { 'osiam::postgresql::user': }->
        class { 'osiam::postgresql::database': }
    } else {
        fail('Unsupported Operatingsystem')
    }

}
