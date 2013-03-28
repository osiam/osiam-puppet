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
