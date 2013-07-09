require 'puppet/resource'
require 'puppet/resource/catalog'
require 'digest/md5'
require 'fileutils'
require 'etc'
require 'facter'
require 'yaml'

Puppet::Type.type(:osiamclient).provide(:osiamclient) do
	desc "osiamclient provider."
	include Puppet::Util::Execution
	include Puppet::Util::Warnings

	def psql
        psql = "export PGPASSWORD=#{@resource[:dbconnection]['password']};"
        psql += "psql -w -h #{@resource[:dbconnection]['host']}"
        psql += " -U #{@resource[:dbconnection]['user']}"
        psql += " -d #{@resource[:dbconnection]['name']}"
	end

    def redirect_uri
        "http://#{@resource[:hostname]}:5000/oauth2"
    end

    def hibernate_sequence
        output = %x{#{psql} --no-align -tc "SELECT last_value FROM hibernate_sequence"}
        output.to_i
    end

    def hibernate_sequence_up
        output = %x{#{psql} -c "SELECT pg_catalog.setval\
            ('hibernate_sequence', #{hibernate_sequence + 1}, false);"}
        raise Puppet::Error, "Failed to set hibernate sequence: #{output}" if $?.exitstatus != 0
    end

    def delete_client(internal_id)
        output = %x{#{psql} -c "DELETE FROM osiam_client_scopes WHERE id = #{internal_id};"}
        raise Puppet::Error, "Failed to delete client scope: #{output}" if $?.exitstatus != 0

        output = %x{#{psql} -c "DELETE FROM osiam_client WHERE internal_id = #{internal_id};"} 
        raise Puppet::Error, "Failed to delete client: #{output}" if $?.exitstatus != 0
    end

    def delete_similar
        [
            { :key => 'id',             :value => @resource[:id] },
            { :key => 'redirect_uri',   :value => redirect_uri },
            { :key => 'client_secret',  :value => @resource[:secret] },
        ].each do |item|
            output = %x{#{psql} --no-align -tc "SELECT internal_id FROM osiam_client \
                WHERE #{item[:key]} = '#{item[:value]}';"}
            self.delete_client(output) unless output.empty? 
        end
    end

    def create
        self.delete_similar

        output = %x{#{psql} -c "INSERT INTO osiam_client VALUES(#{hibernate_sequence},
            '#{@resource[:id]}',
            '#{redirect_uri}',
            '#{@resource[:secret]}',
            '2342','2342','1337','f');"}
        raise Puppet::Error, "Failed to add client: #{output}" if $?.exitstatus != 0

        [ 'GET', 'POST', 'PUT', 'PATCH', 'DELETE' ].each do |action|
            output = %x{#{psql} -c "INSERT INTO osiam_client_scopes \
                VALUES(#{hibernate_sequence}, '#{action}');"}
            raise Puppet::Error, "Failed to add client scope: #{output}" if $?.exitstatus != 0
        end

        self.hibernate_sequence_up
    end

	def destroy
	end

	def exists?
        debug "osiamclient hostname:\t#{@resource[:hostname]}"
        debug "osiamclient id:\t#{@resource[:id]}"
        debug "osiamclient secret:\t#{@resource[:secret]}"
        debug "osiamclient database:\t#{@resource[:dbconnection]['host']}"

        output = %x{#{psql} -c "SELECT id FROM osiam_client WHERE \
            id              = '#{@resource[:id]}' AND
            redirect_uri    = '#{redirect_uri}' AND
            client_secret   = '#{@resource[:secret]}'"}
        output =~ /#{@resource[:id]}/ ? true : false
	end
end
