require 'puppet/type'

Puppet::Type.newtype(:dbschema) do
	@doc = "Install OSIAM database schema"

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
	newparam(:artifactpath) do
		desc "Path to artifact."
	end
	newparam(:osiampath) do
		desc "Path to osiam directory."
	end
	newparam(:dbhost) do
		desc "Hostname of database server."
	end
	newparam(:dbuser) do
		desc "Database user name."
	end
	newparam(:dbpassword) do
		desc "Database user password."
	end
	newparam(:dbname) do
		desc "Database name."
	end
	newparam(:dbforceschema) do
		desc "Path to artifact."
	end

	newproperty(:schemafiles) do
		desc "Manage Schema sql files."
		defaultto(true)
	end
end
