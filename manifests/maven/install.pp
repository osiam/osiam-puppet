class osiam::maven::install {
    $version    = '2.2.1'
    $artifact   = "apache-maven-${version}-bin.tar.gz"
    $repository = 'http://archive.apache.org/dist/maven/binaries'
    $tmp        = "/tmp/${artifact}"

    exec { 'download':
        path    => '/usr/bin',
        command => "wget -O ${tmp} ${repository}/${artifact}",
        creates => "${tmp}",
    }

    exec { 'extract':
        path    => '/bin',
        cwd     => '/opt',
        command => "tar xzf ${tmp}",
        creates => "/opt/apache-maven-${version}",
        require => Exec['download'],
    }

    file { '/usr/bin/mvn':
        ensure => link,
        target => "/opt/apache-maven-${version}/bin/mvn",
    }
}
