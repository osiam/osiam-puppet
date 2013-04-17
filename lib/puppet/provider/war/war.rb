require 'puppet/resource'
require 'puppet/resource/catalog'
require 'fileutils'
require 'etc'

Puppet::Type.type(:war).provide(:war) do
	desc "War provider."
	include Puppet::Util::Execution
	include Puppet::Util::Warnings

	def owner
		artifactid	= @resource[:artifactid]
		path		= @resource[:path]
		artifact	= "#{path}/#{artifactid}.war"

		uid = File.stat("#{artifact}").uid
		Etc.getpwuid(uid).name
	end
	def owner=(owner)
		artifactid	= @resource[:artifactid]
		path		= @resource[:path]
		owner		= @resource[:owner]
		artifact	= "#{path}/#{artifactid}.war"

		begin
			File.chown(Etc.getpwnam(owner).uid,nil,artifact)
		rescue => detail
			raise Puppet::Error, "Failed to set owner to '#{owner}': #{detail}"
		end
	end
	def group
		artifactid	= @resource[:artifactid]
		path		= @resource[:path]
		artifact	= "#{path}/#{artifactid}.war"

		gid = File.stat("#{artifact}").gid
		Etc.getgrgid(gid).name
	end
	def group=(group)
		artifactid	= @resource[:artifactid]
		path		= @resource[:path]
		group		= @resource[:group]
		artifact	= "#{path}/#{artifactid}.war"

		begin
			File.chown(nil,Etc.getgrnam(group).gid,artifact)
		rescue => detail
			raise Puppet::Error, "Failed to set group to '#{group}': #{detail}"
		end
	end

	def create
		version		= @resource[:version]
		artifactid	= @resource[:artifactid]
		path		= @resource[:path]
		owner		= @resource[:owner]
		owner		= owner.nill? || owner.empty? ? "root" : owner
		group		= @resource[:group]
		group		= group.nill? || group.empty? ? "root" : group
		artifact	= "#{path}/#{artifactid}.war"
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
		mvn = mvn + " -DremoteRepositories=#{repository} -Ddest='#{artifact}'"
		
		# Execute maven and download artifact
		command = ["mvn #{mvn}"]
		output, status	= Puppet::Util::SUIDManager.run_and_capture(command, 'root', 'root')
		debug output if status.exitstatus == 0
		debug "Exit Status = #{status.exitstatus}"

		# Change artifact permission
		#command = ["chown #{owner}:#{group} #{artifact}"]
		#output, status	= Puppet::Util::SUIDManager.run_and_capture(command, 'root', 'root')
		#debug output if status.exitstatus == 0
		#debug "Exit Status = #{status.exitstatus}"
		begin
			File.chown(Etc.getpwnam(owner).uid,Etc.getgrnam(group).gid,artifact)
		rescue => detail
			raise Puppet::Error, "Failed to set group to '#{group}': #{detail}"
		end
	end

	def destroy
		artifactid	= @resource[:artifactid]
		path		= @resource[:path]
		artifact	= "#{path}/#{artifactid}.war"
		File.delete(artifact)
	end

	def exists?
		version		= @resource[:version]
		artifactid	= @resource[:artifactid]
		path 		= @resource[:path]
		groupid		= 'org/osiam/ng'

		if version =~ /^.*-SNAPSHOT$/
			repository = 'http://repo.osiam.org/snapshots'
		else
			repository = 'http://repo.osiam.org/release'
		end
		url = "#{repository}/#{groupid}/#{artifactid}/#{version}"


		if File.exists?("#{path}/#{artifactid}.war")
			# Get our artifacts md5sum
			command = ["md5sum #{path}/#{artifactid}.war | cut -d ' ' -f 1"]
			warmd5, status	= Puppet::Util::SUIDManager.run_and_capture(command, 'root', 'root')
			debug warmd5 if status.exitstatus == 0
			debug "Exit Status = #{status.exitstatus}"
			warmd5 = warmd5.sub("\n",'')

			# Get newest artifacts md5sum (from repo)
			# Download the index of #{repository}
			command = [ "wget -O- #{url} 2>&1 | grep '.war' | grep '.md5' | tail -n 1" ]
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

			if md5sum == warmd5
				return true
			else
				return false
			end
		else
			return false
		end
	end
end
