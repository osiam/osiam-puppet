# Class: osiam::tomcat::config
#
# This class configures tomcat 7 on a CentOS 6 system.
# firewall rule is set up.
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
#   class { 'osiam::tomcat::install': }
#
# Authors:
#   Kevin Viola Schmitz <k.schmitz@tarent.de>
#
class osiam::tomcat::config inherits osiam::params {
    $shared_loader  = $osiam::homedir
    $pass           = $osiam::params::tomcat_keyPass

    file { 'catalina.properties':
        ensure  => $osiam::ensure,
        path    => "${osiam::params::tomcat_conf_path}/catalina.properties",
        content => template('osiam/catalina.properties.erb'),
        require => Class['osiam::tomcat::install'],
        notify  => Service[$osiam::params::tomcat_service],
    }

    if $::operatingsystem == "Debian" {
        file { 'tomcat-init':
            ensure  => $osiam::ensure,
            path    => '/etc/init.d/tomcat7',
            source  => 'puppet:///modules/osiam/tomcat7',
            require => Class['osiam::tomcat::install'],
            notify  => Service[$osiam::params::tomcat_service],
        }
    }

    service { $osiam::params::tomcat_service:
        ensure  => $osiam::service_ensure,
        enable  => $osiam::service_enable,
        require => Class['osiam::tomcat::install'],
    }

    exec { 'create key':
        path    => '/usr/bin/',
        command => "keytool -genkey -alias tomcat -keyalg RSA -keystore /etc/ssl/.keystore \
            -storepass ${osiam::params::tomcat_storePass} \
            -keypass ${osiam::params::tomcat_keyPass} \
            -dname \"CN=172.26.5.122, OU=OSIAM, O=tarent AG, L=Bonn, ST=NRW, C=DE\"",
        unless  => "keytool -list -keystore /etc/ssl/.keystore \
            -storepass ${osiam::params::tomcat_storePass} -alias tomcat",
    }

    file { "server.xml":
        ensure  => $osiam::ensure,
        mode    => '0644',
        path    => "${osiam::params::tomcat_conf_path}/server.xml",
        owner   => $osiam::params::tomcat_owner,
        group   => $osiam::params::tomcat_group,
        content => template('osiam/server.xml.erb'),
        notify  => Service[$osiam::params::tomcat_service],
        require => Exec["create key"],
    }

    file { "web.xml":
        ensure  => $osiam::ensure,
        mode    => '0644',
        path    => "${osiam::params::tomcat_conf_path}/web.xml",
        owner   => $osiam::params::tomcat_owner,
        group   => $osiam::params::tomcat_group,
        content => template('osiam/web.xml.erb'),
        notify  => Service[$osiam::params::tomcat_service],
        require => Exec["create key"],
    }
}
