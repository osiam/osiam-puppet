class osiam::tomcat::config {
    if ( $::operatingsystem == 'CentOS' ) or ( $::lsbmajdistrelease == '6') {
        $shared_loader = '/etc/osiam'
        file { 'catalina.properties':
            path    => '/usr/share/tomcat7/conf/catalina.properties',
            ensure  => file,
            require => Package['tomcat7'],
            content => template('osiam/catalina.properties.erb'),
            notify  => Service['tomcat7']
        }
        service { 'tomcat7':
             ensure  => running,
             require => Package['tomcat7'],
        }
    }
}
