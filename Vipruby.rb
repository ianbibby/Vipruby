require 'rest_client'
require 'nokogiri'

# Adding to_hash method to Nokogiri class 
class Nokogiri::XML::Node
  TYPENAMES = {1=>'element',2=>'attribute',3=>'text',4=>'cdata',8=>'comment'}
  def to_hash
    {kind:TYPENAMES[node_type],name:name}.tap do |h|
      h.merge! nshref:namespace.href, nsprefix:namespace.prefix if namespace
      h.merge! text:text
      h.merge! attr:attribute_nodes.map(&:to_hash) if element?
      h.merge! kids:children.map(&:to_hash) if element?
    end
  end
end

class Nokogiri::XML::Document
  def to_hash; root.to_hash; end
end

class Vipruby
  attr_accessor :tenant_uid, :proxy_token, :auth_token, :base_url
  SSL_VERSION = 'TLSv1'
  
  def initialize(base_url,proxy_token,user_name,password)
    #add condition later for trusted certs (This ignores)
    #OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
    self.proxy_token = proxy_token
    self.base_url = base_url
    self.auth_token = get_auth_token(user_name,password)
    self.tenant_uid = get_tenant_uid
  end
  
  def get_tenant_uid
    Nokogiri::XML(RestClient::Request.execute(method: :get,url: "#{base_url}/tenant",
      headers: {:'X-SDS-AUTH-TOKEN' => @auth_token, 
        :'X-SDS-AUTH-PROXY-TOKEN' => @proxy_token
      },
      ssl_version: SSL_VERSION
      )).to_hash[:kids][2][:text]
  end
  
  def login(user_name,password)
    RestClient::Request.execute(method: :get,url: "#{base_url}/login", user: user_name, password: password,ssl_version: SSL_VERSION)
  end
  
  def get_auth_token(user_name,password)
    login(user_name,password).headers[:x_sds_auth_token]
  end
  
  def add_host(host)
     RestClient::Request.execute(method: :get,url: "#{base_url}/tenants/#{@tenant_uid}/hosts",ssl_version: SSL_VERSION,payload: host)
     self.add_initiators()
  end
  
  def add_initiators
    
  end
  
  
  
  def self.getHost(uid)
    
  end
  
  private :login, :get_auth_token, :get_tenant_uid
end

class Host
  attr_accessor :fqdn, :ip_address, :type, :name, :discoverable, :initiators
  
  def initialize params = {}
    params.each { |key, value| send "#{key}=", value }
  end
  
  def generate_xml
    Nokogiri::XML::Builder.new do |xml|
      xml.host_create {
        xml.type @type
        xml.name @name
        xml.host_name @fqdn
        xml.discoverable @discoverable
      }
    end
  end
  
end