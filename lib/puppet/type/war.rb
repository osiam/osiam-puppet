require 'puppet/type'

Puppet::Type.newtype(:war) do
    @doc = "War download"

    # Make this type accept "ensure => present" and "ensure => absent".
    # present will call providers function 'exists?' and 'create'.
    # absent will call providers function 'exists?' and 'destroy'.
    # default value is 'present'.
    ensurable do
        self.defaultvalues
        defaultto :present
    end

    def self.title_patterns
        [ [ /^(.*?)\/*\Z/m, [ [ :artifactid, lambda{|x| x} ] ] ] ]
    end

    # Create parameters for this type. They will be used by the provider
    newparam(:artifactid) do
        desc "War artifact name."
        isnamevar
    end
    newparam(:version) do
        desc "War artifact version."
    end
    newparam(:path) do
        desc "Location where the war file will be saved."
    end

    newparam(:id) do
        desc "Build timestamp and buildnumber. Useful for getting specific snapshot releases."
    end

    # Create properties. These will call a provider function to check
    # for a value and another function to enforce it.
    #
    # owner for example will call function "owner" which will check
    # for ownership of the file that is being deploying with this type.
    # If the file is not owner by whom it should be, the function
    # owner=(owner) will be called to set things straight.
    newproperty(:owner) do
        desc "Owner that will be set for the artifact."
    end
    newproperty(:group) do
        desc "Group that will be set for the artifact."
    end

end
