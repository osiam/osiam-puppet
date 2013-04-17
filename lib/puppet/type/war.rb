require 'puppet/type'

Puppet::Type.newtype(:war) do
	@doc = "War download"

	ensurable do
		self.defaultvalues
		defaultto :present
	end

	def self.title_patterns
		[ [ /^(.*?)\/*\Z/m, [ [ :artifactid, lambda{|x| x} ] ] ] ]
	end

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
	newproperty(:owner) do
		desc "Owner that will be set for the artifact."
	end
	newproperty(:group) do
		desc "Group that will be set for the artifact."
	end

end
