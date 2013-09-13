require 'digest/md5'
require 'puppet/resource'
require 'puppet/resource/catalog'
require 'digest/md5'
require 'fileutils'
require 'etc'
require 'rexml/document'
include REXML

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
        path        = @resource[:path]
        owner       = @resource[:owner].nil? || @resource[:owner].empty? ? "root" : @resource[:owner]
        group       = @resource[:group].nil? || @resource[:group].empty? ? "root" : @resource[:group]

        output = %x{wget -qO #{self.artifact} #{@remoteartifact}}
        raise Puppet::Error, "Failed to download artifact: #{output}" if $?.exitstatus != 0

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

    def placeholdsetter
        @version        = @resource[:version]
        @artifactid     = @resource[:artifactid]
        @path           = @resource[:path]
        @groupid        = 'org/osiam'
        @repository     = 'http://maven-repo.evolvis.org'
        @remoteartifact = self.remoteArtifact
    end

    # Function to check if file exists.
    # In this case it will also check its md5sum and
    # compare it to the newest artifact
    # (of the same version) in the repository.
    def exists?
        placeholdsetter

        if File.exists?("#{@path}/#{@artifactid}.war")
            debug "#{@artifactid}: Artifact exists. Comparing md5sum."
            # Get md5sum of local and remote artifact and compare
            localmd5    = Digest::MD5.hexdigest(File.read("#{@path}/#{@artifactid}.war"))
            remotemd5   = getTargetMd5

            debug "#{@artifactid}: local file: #{localmd5}"
            debug "#{@artifactid}: remote file: #{remotemd5}"
            return localmd5 == remotemd5 ? true : false
        else
            debug "#{@artifactid}: Artifact doesn't exist."
            return false
        end
    end

    def getTargetMd5
        debug "#{@artifactid}: Remote artifact #{@remoteartifact}."
        debug "#{@artifactid}: downloading artifact md5sum."
        md5sum = %x{wget -qO- #{@remoteartifact}.md5}
        raise Puppet::Error, "Failed to download md5file: #{md5sum}" if $?.exitstatus != 0

        return md5sum
    end

    def remoteArtifact
        if @version =~ /^.*-SNAPSHOT$/
            debug "#{@artifactid}: Snapshot version."
            repository = @repository + '/snapshots'

            # Get timestamp and buildnumber of most current snapshot release if id was not given
            if @resource[:id].nil?
                debug "#{@artifactid}: No id given. Extracting information from maven-metadata.xml."
                # Download maven-metadata.xml
                %x{wget -O maven-metadata.xml #{repository}/#{@groupid}/#{@artifactid}/#{@version}/maven-metadata.xml 2>&1}
                raise Puppet::Error, "Failed to download maven-metadata.xml: #{output}" if $?.exitstatus != 0

                # Extract latest build timestamp and buildnumber
                file        = File.new('./maven-metadata.xml')
                mvnmd       = Document.new(file)
                snapshot    = mvnmd.root.elements['versioning'].elements['snapshot']
                timestamp   = snapshot.elements['timestamp'].text
                buildnumber = snapshot.elements['buildNumber'].text
                id          = timestamp + '-' + buildnumber
                debug "#{@artifactid}: id: #{id}"
            else
                debug "#{@artifactid}: id given: #{id}."
                id = @resource[:id]
            end

            versionshort    = @version.sub(/^(.*)-SNAPSHOT$/,'\1')
            remoteartifact  = "#{repository}/#{@groupid}/#{@artifactid}/#{@version}/#{@artifactid}"
            remoteartifact += "-#{versionshort}-#{id}.war"

            return remoteartifact
        end
    end
end
