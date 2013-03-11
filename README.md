osiam-puppet
============

This repository conatins the [OSIAM NG Puppet Manifest](manifests/init.pp).

The [manifest](manifests/init.pp) currently deploys the OSIAM NG *authorization-server* and the *oauth2-client* war files to an existing application server (tested with Tomcat 7) when `$ensure` is set to "present" or removes the files and their installation directories when `$ensure`is set to "absend".

Further useage information can be found in the [manifest's header](manifests/init.pp).

