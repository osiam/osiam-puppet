osiam-puppet
============

This repository conatins the [OSIAM NG Puppet Manifest](manifests/init.pp).

The [manifest](manifests/init.pp) currently deploys the OSIAM NG *authorization-server* and the *oauth2-client* war files to an existing application server (tested with Tomcat 7) and initializes the database when `$ensure` is set to "present" or removes the files from their installation directories and cleans the database when `$ensure`is set to "absend". By default this module will install and configure Postgres 9.2 and Tomcat 7.

Prerequisite
============
Puppet:
* [puppet-maven](https://github.com/maestrodev/puppet-maven)
* [puppet-wget](https://github.com/maestrodev/puppet-wget)

Host:
* OS: Centos 6
* maven
* unzip

Usage
============
Use the following example to install everything including postgresql 9.2 and tomcat 7. This will install Osiam Version 0.3 and initialize the database 'osiam' on the same maschine. War files will be deployed to `/var/lib/tomcat7/webapps`
```puppet
  class { 'osiam':
        ensure  => present,
        version => '0.3',
  }
```
If you want to manage your database and application server by yourself use this example:
```puppet
  class { 'osiam':
        ensure          => present,
        version         => '0.3',
        installdb       => false,
        dbhost          => '<database_host>',
        dbname          => '<database_name>',
        dbuser          => '<database_user>',
        dbpassword      => '<database_password>',
        installas       => false,
        webappsdir      => '<webapps_directory>',
        owner           => '<application_server_owner>',
        group           => '<application_server_group>',
  }
```

Further useage information can be found in the [manifest's header](manifests/init.pp).
