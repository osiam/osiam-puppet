require 'puppet/type'

Puppet::Type.newtype(:osiamclient) do
    @doc = "Install OSIAM database schema"

    ensurable do
        self.defaultvalues
        defaultto :present
    end

    def self.title_patterns
        [ [ /^(.*?)\/*\Z/m, [ [ :hostname ] ] ] ]
    end

    newparam(:hostname) do
        desc "Client hostname. Used for redirect URI."
        isnamevar
    end
    newparam(:id) do
        desc "Client ID. String expected."
    end
    newparam(:secret) do
        desc "Client secret. String expected."
    end
    newparam(:dbconnection) do
        desc "Expect hash with the following keys: host, name, user, password."
    end
end
