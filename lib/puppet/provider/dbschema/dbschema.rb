require 'puppet/resource'
require 'puppet/resource/catalog'
require 'digest/md5'
require 'fileutils'
require 'etc'

Puppet::Type.type(:dbschema).provide(:dbschema) do
	desc "dbschema provider."
	include Puppet::Util::Execution
	include Puppet::Util::Warnings

	def set_variables
		@osiampath	= @resource[:osiampath]
		@dbhost 	= @resource[:dbhost]
		@dbname 	= @resource[:dbname]
		@dbuser 	= @resource[:dbuser]
		@dbpassword	= @resource[:dbpassword]
		@dbforceschema	= @resource[:dbforceschema]
		@initsrc	= 'WEB-INF/classes/sql/init.sql'
		@inittmp	= "/tmp/install-schema.sql"
		@inittar	= "#{@osiampath}/install-schema.sql"
		@rmtsrc		= 'WEB-INF/classes/sql/drop.sql'
		@rmttmp		= "/tmp/remove-schema.sql"
		@rmttar		= "#{@osiampath}/remove-schema.sql"
		@artifact	= @resource[:artifactpath] + '/' + @resource[:artifactid] + '.war'
	end

	def extractschema(source,target)
		# Extract Schema
		command = [ "unzip -p #{@artifact} #{source} > #{target}" ]
		output, status	= Puppet::Util::SUIDManager.run_and_capture(command, 'root', 'root')
        # Opens the sql file and replaces localhost with a propper hostname
        editedSQLFile = File.read(target).gsub(/localhost/, dbhost)
        # Overrides the original SQL File with the edited string...
        File.open(target, "w"){|file| file.write(editedSQLFile)}
        debug output if status.exitstatus == 0
		debug "Exit Status = #{status.exitstatus}"
		if status.exitstatus != 0
			raise Puppet::Error, "Failed to extract OSIAM database schema: #{output}"
		end
	end

	def create
		self.extractschema(@initsrc,@inittar)
		self.extractschema(@rmtsrc,@rmttar)

		psql = "export PGPASSWORD=#{@dbpassword};"
		psql += "psql -h #{@dbhost} -U #{@dbuser} -d #{@dbname} -w < #{@inittar}"
		output, status	= Puppet::Util::SUIDManager.run_and_capture(["#{psql}"], 'root', 'root')
		debug output if status.exitstatus == 0
		debug "Exit Status = #{status.exitstatus}"
		if status.exitstatus != 0
			raise Puppet::Error, "Failed to dump OSIAM database schema: #{output}"
		end
	end

	def destroy
		if File.exists?(@rmttar)
			psql = "export PGPASSWORD=#{@dbpassword};"
			psql += "psql -h #{@dbhost} -U #{@dbuser} -d #{@dbname} -w < #{@rmttar}"
			output, status	= Puppet::Util::SUIDManager.run_and_capture(["#{psql}"], 'root', 'root')
			debug output if status.exitstatus == 0
			debug "Exit Status = #{status.exitstatus}"
			if status.exitstatus != 0
				raise Puppet::Error, "Failed to remove OSIAM database schema: #{output}"
			end
		end
	end

	def exists?
		self.set_variables

		psql = "export PGPASSWORD=#{@dbpassword};"
		psql += "psql -h #{@dbhost} -U #{@dbuser} -d #{@dbname} -w"
		psql += ' -c \'select * from scim_meta\''
		%x{#{psql} 2>&1}
		exists = $?.exitstatus == 0 ? true : false

		if exists && @dbforceschema
			if File.exists?(@inittar)
				self.extractschema(@initsrc,@inittmp)	
				oldmd5 = Digest::MD5.hexdigest(File.read(@inittar))
				newmd5 = Digest::MD5.hexdigest(File.read(@inittmp))
				exists = false unless oldmd5 == newmd5
			else exists = false end
		end

		exists
	end

	def schemafiles
		File.exists?(@inittar) && File.exists?(@rmttar) ? true : false
	end

	def schemafiles=(value)
		self.extractschema(@initsrc,@inittar)
		self.extractschema(@rmtsrc,@rmttar)
	end
end
