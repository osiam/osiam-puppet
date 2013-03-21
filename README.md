osiam-puppet
============

This repository conatins the [OSIAM NG Puppet Manifest](manifests/init.pp).

The [manifest](manifests/init.pp) currently deploys the OSIAM NG *authorization-server* and the *oauth2-client* war files to an existing application server (tested with Tomcat 7) and initializes the database when `$ensure` is set to "present" or removes the files from their installation directories and cleans the database when `$ensure`is set to "absend".

Prerequisite
============
Puppet:
* [puppet-maven](https://github.com/maestrodev/puppet-maven)
* [puppet-wget](https://github.com/maestrodev/puppet-wget)

Host:
* OS: Centos 6
* Java 1.7
* maven
* Tomcat 7
* Postgresql 9.2
* unzip

Usage
============
The following will install Osiam Version 0.3 and initialize the database 'osiam' on the same maschine. War files will be deployed to `/var/lib/tomcat7/webapps`
```puppet
  class { 'osiam':
    ensure      => present,
    version     => '0.3',
    dbuser      => 'osiam',
    dbpassword  => 'mypassword',
    dbname      => 'osiam',
  }
```

Further useage information can be found in the [manifest's header](manifests/init.pp).
