require 'rest-client'
require 'json'

# The Following Host calls will get Host information for all tenants
module ViprHost

    # generate JSON for Host POST
    #
    # @param host_type [String] Type of Host. Required Param.
    # @param ip_or_dns [String] IP Address or FQDN of the host to add. Required Param.
    # @param name [String] Arbitrary name given to the host. Required Param
    # @param port [String] Port for connecting to the specfic host. Will be autogenerated if not specified by the {#add_host} method
    # @param user_name [String] User Name to connect to this host. 
    # @param password [String] Password for the Username to connect to this host. 
    # @param use_ssl [String] True or False
    # @param discoverable [String] True or False for searching initators after being added.
    #
    # @return [JSON] The JSON object for the POST operation
    def generate_host_post_json(host_type, ip_or_dns, name, port, user_name, password, use_ssl, discoverable)
        payload = {
            type: host_type,
            host_name: ip_or_dns,
            name: name,
            port_number: port,
            user_name: user_name,
            password: password,
            use_ssl: use_ssl,
            discoverable: discoverable
        }.to_json

        return payload
    end
      
    # generate JSON for Initators POST
    #
    # @param protocol [String] Type of protocol. Required Param
    # @param initiator_node [String] Node string. Required Param
    # @param initiator_port [Array] Ports should be passed as an array. Every port will be added into another array for the entire JSON object
    #
    # @return [ARRAY] JSON objects will be put into an Array
    def generate_initiators_json(protocol, initiator_node, initiator_port)
        initiator_json = []
        initiator_port.each do |initiator|
            initiator_json << 
            {
                protocol: protocol,
                initiator_node: initiator_node,
                initiator_port: initiator
            }.to_json
        end
        return initiator_json
    end

    # Add a host to ViPR
    #
    # @param host_type [String] Type of Host. "Windows", "Linux", or, "HPUX". Required Param
    # @param ip_or_dns [String] IP Address or FQDN of host. Required Param
    # @param name [String] Arbitrary Name only necesary and identifiable by ViPR. Required Param.
    # @param user_name [String] User Name to connect to the host. Required Param
    # @param password [String] Password for the User Name to connect to the host. Required Param
    # @param port [String] Port to connect to the host. Optional Param. Defaults will be used if no param is passed
    # @param use_ssl [String] Whether SSL is used. Trur or False. Optional Param
    # @param discoverable [String] True or False. Initators and Nodes will be discovered after being added. By default this is true
    #
    # @return [JSON] returns host information
    #
    # @example
    #   vipr.add_host('Windows', 'windowshost.mydomain.org', 'WindowsHOST' 'DOMAIN\user', 'userpw')
    #   vipr.add_host('Windows', 'windowshost.mydomain.org', 'WindowsHOST' 'DOMAIN\user', 'userpw', '453', 'true', 'true')
    #   vipr.add_host('Linux', 'linuxhost.mydomain.org', 'LinuxHOST' 'DOMAIN\user', 'userpw')
    def add_host(host_type=nil, ip_or_dns=nil, name=nil, user_name=nil, password=nil, port=nil, use_ssl=nil, discoverable=nil, auth=nil, cert=nil)
        check_host_post(host_type, ip_or_dns, name, user_name, password)
        host_type = host_type.split('_').collect(&:capitalize).join

        if host_type == "Windows" 
            use_ssl.nil? ? use_ssl = false : use_ssl
            if use_ssl == true
                port.nil? ? port = '5986' : port
            else
                port.nil? ? port = '5985' : port
            end
            discoverable.nil? ? discoverable = true : discoverable
            user_name.nil? ? user_name = "admin" : user_name
            password.nil? ? password = "#1Password" : password
        elsif host_type == "Linux"
            use_ssl.nil? ? use_ssl = false : use_ssl
            port.nil? ? port = '22' : port = port
            discoverable.nil? ? discoverable = true : discoverable
            user_name.nil? ? user_name = "admin" : user_name
            password.nil? ? password = "#1Password" : password
        elsif host_type == "Hpux"
            host_type = "HPUX"
        end
        rest_post(generate_host_post_json(host_type, ip_or_dns, name, port, user_name, password, use_ssl, discoverable), "#{@base_url}/tenants/#{@tenant_uid}/hosts", auth.nil? ? @auth_token : auth, cert.nil? ? @verify_cert : cert)
    end

    # Add an initiator to a host in ViPR
    #
    # @param host_id [String] The Host UID. Required Param.
    # @param protocol [String] The protocol type. iSCSI or FC. Required
    # @param initiator_port [String] Initator Port as a string. Required
    # @param initiator_node [Array] Initator Nodes must be passed in as strings in an array. Required.
    #
    # @example
    #   x = vipr.get_all_hosts['id'][0]
    #   vipr.add_host_initiator(x, 'FC', '10:13:27:65:60:38:68:BE', ['10:13:27:65:60:38:68:BD','10:13:27:65:60:38:68:BC'])
    def add_host_initiator(host_id=nil, protocol=nil, initiator_port=nil, initiator_node=nil, auth=nil, cert=nil)
        check_host_get(host_id)
        check_host_post_initiator(protocol, initiator_port)

        protocol = protocol.upcase
        if protocol == "ISCSI"
            protocol = "iSCSI"
        end
        initiator_payload_array = generate_initiators_json(protocol, initiator_node, initiator_port)
        initiator_payload_array.each do |i|
            rest_post(i, "#{@base_url}/compute/hosts/#{host_id}/initiators", auth.nil? ? @auth_token : auth, cert.nil? ? @verify_cert : cert)
        end
    end
  
    # Get all Host objects in ViPR
    #
    # @return [JSON] returns a JSON collection of all hosts in ViPR for a particular tenant
    # 
    # @example
    #    vipr.get_all_hosts
    def get_all_hosts(auth=nil, cert=nil)
        rest_get("#{@base_url}/tenants/#{@tenant_uid}/hosts", auth.nil? ? @auth_token : auth, cert.nil? ? @verify_cert : cert)
    end
  
    # Get an individual host's details in ViPR
    #
    # @param host_id [STRING] ID of host to get information. Required Param
    #
    # @return [Hash] the object converted into Hash format and can be parsed with object[0] or object['id'] notation
    # 
    # @example
    #   x = vipr.get_all_hosts['id'][0]
    #   vipr.get_host(x)
    def get_host(host_id=nil, auth=nil, cert=nil)
        check_host_get(host_id)
        rest_get("#{@base_url}/compute/hosts/#{host_id}", auth.nil? ? @auth_token : auth, cert.nil? ? @verify_cert : cert)
    end
  
    # Deactive and Remove a Host from ViPR
    #
    # @param host_id [STRING] ID of host to get information. Required Param
    #
    # @return [JSON] returns information from POST for removing Host object
    #
    # @example
    #   x = vipr.get_all_hosts['id'][0]
    #   vipr.deactivate_host(x)
    def deactivate_host(host_id=nil, auth=nil, cert=nil)
        check_host_get(host_id)
        rest_post(nil, "#{@base_url}/compute/hosts/#{host_id}/deactivate", auth.nil? ? @auth_token : auth, cert.nil? ? @verify_cert : cert)
    end
  
    # Determine if a host already exists in ViPR
    #
    # @param hostname [STRING] The name of the host to search for. Requires full name and not partials
    #
    # @return [BOOLEAN] returns TRUE/FALSE 
    #
    # @example
    #   vipr.host_exists?('windowslab.mydomain.com')
    def host_exists?(hostname, auth=nil, cert=nil)
        hostname = hostname.downcase
        host_array = []
        hosts = get_all_hosts
        hosts.each do |key, value|
          value.each do |k|
            host_array << k['name'].to_s.downcase
          end
        end
       host_array.include?(hostname) 
    end
  
    # Find and return query results for a host in ViPR
    #
    # @param search_param [STRING] Value to search host for. This will work with partials
    #
    # @return [JSON] returns search results
    #
    # @example
    #   vipr.find_host_object('host1')
    def find_host_object(search_param, auth=nil, cert=nil)
      rest_get("#{@base_url}/compute/hosts/search?name=#{search_param}", auth.nil? ? @auth_token : auth, cert.nil? ? @verify_cert : cert)
    end

    private
    # Error Handling method to check for Missing Host Post params. If the pass fails, an error exception is raised
    #
    # @param host_type [String] Requires the string of the host type. 
    # @param ip_or_dns [String] Requires the string of the IP Address or FQDN. 
    # @param name [String] Requires the string of the Arbitrary name for ViPR. 
    # @param user_name [String] Requires the string of the User Name for access. 
    # @param password [String] Requires the string of the Password of the User Name for access
    #
    # @return [Boolean] True if pass, false if it fails
    #
    # @private
    def check_host_post(host_type, ip_or_dns, name, user_name, password)
      if host_type == nil || ip_or_dns == nil || name == nil
          raise "Missing a Required param (host_type, ip_or_dns, name)"
      end
    end

    # Error Handling method to check for Missing Host ID param. If the pass fails, an error exception is raised
    #
    # @param host_id [String] Requires the string of the vcenter uid
    # @return [Boolean] True if pass, false if it fails
    #
    # @private
    def check_host_get(host_id)
      if host_id == nil
          raise "Missing the Required param (host_id). Find the host_id by using the get_all_hosts method."
      end
    end

    # Error Handling method to check for Initiator params. If the pass fails, an error exception is raised
    #
    # @param protocol [String] Requires the string of the Port
    # @param initiator_port [String] Requires the string of the initiator_port
    # @return [Boolean] True if pass, false if it fails
    #
    # @private
    def check_host_post_initiator(protocol, initiator_port)
      if protocol== nil || initiator_port == nil
          raise "Missing the Required param (protocol or initiator_port)."
      end
    end

end