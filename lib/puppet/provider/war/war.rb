require 'puppet/resource'
require 'puppet/resource/catalog'
require 'digest/md5'
require 'fileutils'
require 'etc'

Puppet::Type.type(:war).provide(:war) do
	desc "War provider."
	include Puppet::Util::Execution
	include Puppet::Util::Warnings

	def artifact
		@resource[:path] + '/' + @resource[:artifactid] + '.war'
	end

	# Function to get file owner.
	def owner
		uid = File.stat(self.artifact).uid
		Etc.getpwuid(uid).name
	end
	# Function to enforce file owner.
	def owner=(owner)
		owner = @resource[:owner]

		begin
			File.chown(Etc.getpwnam(owner).uid,nil,self.artifact)
		rescue => detail
			raise Puppet::Error, "Failed to set owner to '#{owner}': #{detail}"
		end
	end
	# Function to get file group.
	def group
		gid = File.stat(self.artifact).gid
		Etc.getgrgid(gid).name
	end
	# Function to enforce file group.
	def group=(group)
		group = @resource[:group]

		begin
			File.chown(nil,Etc.getgrnam(group).gid,self.artifact)
		rescue => detail
			raise Puppet::Error, "Failed to set group to '#{group}': #{detail}"
		end
	end

	# Function to create file.
	# Will be called if ensure is set to 'present'.
	def create
		version		= @resource[:version]
		artifactid	= @resource[:artifactid]
		path		= @resource[:path]
		owner		= @resource[:owner]
		owner		= owner.nil? || owner.empty? ? "root" : owner
		group		= @resource[:group]
		group		= group.nil? || group.empty? ? "root" : group
		groupid		= 'org.osiam.ng'
		plugin		= "2.4"

		if version =~ /^.*-SNAPSHOT$/
			repository = 'http://repo.osiam.org/snapshots'
		else
			repository = 'http://repo.osiam.org/release'
		end

		# Set maven parameters
		mvn = "org.apache.maven.plugins:maven-dependency-plugin:#{plugin}:get -Dpackaging=war"
		mvn = mvn + " -DgroupId=#{groupid} -DartifactId=#{artifactid} -Dversion=#{version}"
		mvn = mvn + " -DremoteRepositories=#{repository} -Ddest='" + self.artifact + "'"
		
		# Execute maven and download artifact
		command = ["mvn #{mvn}"]
		output, status	= Puppet::Util::SUIDManager.run_and_capture(command, 'root', 'root')
		debug output if status.exitstatus == 0
		debug "Exit Status = #{status.exitstatus}"
		if status.exitstatus != 0
			raise Puppet::Error, "Failed to download artifact: #{output}"
		end
		# Change artifact permission
		begin
			File.chown(Etc.getpwnam(owner).uid,Etc.getgrnam(group).gid,self.artifact)
		rescue => detail
			raise Puppet::Error, "Failed to set group to '#{group}': #{detail}"
		end
	end

	# Function to delete file.
	# Will be called if ensure is set to 'absent'.
	def destroy
		File.delete(self.artifact)
	end

	# Function to check if file exists.
	# In this case it will also check its md5sum and
	# compare it to the newest artifact
	# (of the same version) in the repository.
	def exists?
		version		= @resource[:version]
		artifactid	= @resource[:artifactid]
		path 		= @resource[:path]
		groupid		= 'org/osiam/ng'
		repository 	= 'http://repo.osiam.org'

		repoappend = version =~ /^.*-SNAPSHOT$/ ? 'snaphots' : 'release'
		repository = repository + '/' + repoappend
		url = "#{repository}/#{groupid}/#{artifactid}/#{version}"


		if File.exists?("#{path}/#{artifactid}.war")
			# Get our artifacts md5sum
			warmd5 = Digest::MD5.hexdigest(File.read(self.artifact))

			# Get newest artifacts md5sum (from repo)
			# Download the index of #{repository}
			command = [ "wget -O- #{url} 2>&1 | grep '.war.md5' | tail -n 1" ]
			md5file, status = Puppet::Util::SUIDManager.run_and_capture(command, 'root', 'root')
			debug command if status.exitstatus == 0
			debug "Exit Status = #{status.exitstatus}"
			# Extract the newest wars .md5file file name
			md5file = md5file.sub(/^.*<a href="([^"]*)">.*$/, '\1')
			# Finaly download the md5 sum
			command2 = [ "wget -qO- #{url}/#{md5file}" ]
			md5sum, status	= Puppet::Util::SUIDManager.run_and_capture(command2, 'root', 'root')
			debug md5sum if status.exitstatus == 0
			debug "Exit Status = #{status.exitstatus}"

			# return true if md5sum == warmd5
			return md5sum == warmd5
		else
			return false
		end
	end
end
