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

    def path
        @path = @resource[:path]
    end

    def artifactid
        @artifactid = @resource[:artifactid]
    end

    def artifact
        self.path + '/' + self.artifactid + '.war'
    end

    def version
        @version = @resource[:version]
    end

    def snapshotRepository?
        self.version =~ /^.*-SNAPSHOT$/ ? true : false
    end

    def repository
        @repository = 'http://maven-repo.evolvis.org'
    end

    def repositoryUrl
        type = self.snapshotRepository? ? 'snapshots' : 'releases'
        @repositoryUrl = self.repository + '/' + type
    end

    def groupid
        @groupid = 'org/osiam'
    end

    def downloadMavenMetadata
        debug "#{self.artifactid}: Downloading maven-metadata.xml"
        %x{wget -O maven-metadata.xml #{self.repositoryUrl}/#{self.groupid}/#{self.artifactid}/#{self.version}/maven-metadata.xml 2>&1}
        raise Puppet::Error, "Failed to download maven-metadata.xml: #{output}" if $?.exitstatus != 0
    end

    def getIdFromMavenMetadata
            downloadMavenMetadata
            debug "#{self.artifactid}: Extracting information from maven-metadata.xml."
            file        = File.new('./maven-metadata.xml')
            mvnmd       = Document.new(file)
            snapshot    = mvnmd.root.elements['versioning'].elements['snapshot']
            timestamp   = snapshot.elements['timestamp'].text
            buildnumber = snapshot.elements['buildNumber'].text
            timestamp + '-' + buildnumber
    end

    def id
        @id = @resource[:id].nil? ? self.getIdFromMavenMetadata : @resource[:id]
    end

    def latestArtifactSnapshot
        versionshort            = self.version.sub(/^(.*)-SNAPSHOT$/,'\1')
        latestArtifactSnapshot  = "#{self.repositoryUrl}/#{self.groupid}/#{self.artifactid}/#{self.version}/#{self.artifactid}"
        latestArtifactSnapshot += "-#{versionshort}-#{self.id}.war"
    end

    def getRemoteArtifact
        if self.snapshotRepository?
            debug "#{self.artifactid}: Snapshot version."
            return latestArtifactSnapshot
        else
            debug "#{self.artifactid}: Release version."
            remoteartifact = "#{self.repositoryUrl}/#{self.groupid}/#{self.artifactid}/#{self.version}/#{self.artifactid}-#{self.version}.war"
            return remoteartifact
        end
    end

    def remoteArtifact
        @remoteArtifact ||= self.getRemoteArtifact
    end

    def getTargetMd5
        debug "#{@artifactid}: Remote artifact #{self.remoteArtifact}."
        debug "#{@artifactid}: downloading artifact md5sum."
        md5sum = %x{wget -qO- #{self.remoteArtifact}.md5}
        raise Puppet::Error, "Failed to download md5file: #{md5sum}" if $?.exitstatus != 0
        md5sum
    end

    def localAndRemoteArtifactMd5Equal?
        localmd5    = Digest::MD5.hexdigest(File.read(self.artifact))
        remotemd5   = self.getTargetMd5

        debug "#{self.artifactid}: local file: #{localmd5}"
        debug "#{self.artifactid}: remote file: #{remotemd5}"
        localmd5 == remotemd5 ? true : false
    end

    def exists?
        if File.exists?(self.artifact)
            debug "#{self.artifactid}: Artifact exists. Comparing md5sum."
            localAndRemoteArtifactMd5Equal?
        else
            debug "#{self.artifactid}: Artifact doesn't exist."
            return false
        end
    end

    def artifactOwner
        @owner = @resource[:owner].nil? || @resource[:owner].empty? ? "root" : @resource[:owner]
    end

    def artifactGroup
        @group = @resource[:group].nil? || @resource[:group].empty? ? "root" : @resource[:group]
    end

    def setArtifactPermission
        self.owner= self.artifactOwner
        self.group= self.artifactGroup
    end

    def create
        debug "#{self.artifactid}: Downloading artifact '#{self.remoteArtifact}'."
        output = %x{wget -qO #{self.artifact} #{self.remoteArtifact}}
        raise Puppet::Error, "Failed to download artifact: #{output}" if $?.exitstatus != 0
        self.setArtifactPermission
    end

    # Function to get file owner.
    def owner
        uid = File.stat(self.artifact).uid
        Etc.getpwuid(uid).name
    end
    # Function to enforce file owner.
    def owner=(owner)
        debug "#{self.artifactid}: Changing owner to '#{self.artifactOwner}'."
        begin
            File.chown(Etc.getpwnam(self.owner).uid,nil,self.artifact)
        rescue => detail
            raise Puppet::Error, "Failed to set owner to '#{self.owner}': #{detail}"
        end
    end

    # Function to get file group.
    def group
        gid = File.stat(self.artifact).gid
        Etc.getgrgid(gid).name
    end

    # Function to enforce file group.
    def group=(group)
        debug "#{self.artifactid}: Changing group to '#{self.artifactGroup}'."
        begin
            File.chown(nil,Etc.getgrnam(self.group).gid,self.artifact)
        rescue => detail
            raise Puppet::Error, "Failed to set group to '#{self.group}': #{detail}"
        end
    end

    # Function to delete file.
    # Will be called if ensure is set to 'absent'.
    def destroy
        File.delete(self.artifact)
    end
end

