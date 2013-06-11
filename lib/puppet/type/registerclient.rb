require 'puppet/type'

Puppet::Type.newtype(:registerclient) do
    @doc = "Install OSIAM database schema"

    ensurable do
        self.defaultvalues
        defaultto :present
    end

    def self.title_patterns
        [ [ /^(.*?)\/*\Z/m, [ [ :hostname ] ] ] ]
    end

    newparam(:hostname) do
        desc "Path to osiam directory."
        isnamevar
    end
    newparam(:uuid) do
        desc "Path to osiam directory."
    end
    newparam(:secret) do
        desc "Hostname of database server."
    end
    newparam(:dbconnection) do
        desc "Hostname of database server."
    end
end
