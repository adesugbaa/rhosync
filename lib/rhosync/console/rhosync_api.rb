require 'rest_client'

module RhosyncApi
  class << self

    def get_token(server,login,password)
      res = RestClient.post("#{server}/login",
          {:login => login, :password => password}.to_json, :content_type => :json)
      res.cookies['rhosync_session'] = CGI.escape(res.cookies['rhosync_session'])
      RestClient.post("#{server}/api/get_api_token",'',{:cookies => res.cookies})
    end
    
    def list_users(server,token)
      JSON.parse(RestClient.post("#{server}/api/list_users",
        {:api_token => token}.to_json, :content_type => :json).body)
    end
    
    def create_user(server,token,login,password)
      RestClient.post("#{server}/api/create_user",
        {:api_token => token,:attributes => {:login => login, :password => password}}.to_json, 
         :content_type => :json)
    end  
    
    def delete_user(server,token,user_id)
      RestClient.post("#{server}/api/delete_user",
        {:api_token => token, :user_id => user_id}.to_json, 
         :content_type => :json)    
    end
  
    def list_clients(server,token,user_id)
      JSON.parse(RestClient.post("#{server}/api/list_clients", 
        {:api_token => token, :user_id => user_id}.to_json, :content_type => :json).body)
    end
    
    def create_client(server,token,user_id)
      RestClient.post("#{server}/api/create_client",
        {:api_token => token, :user_id => user_id}.to_json, 
         :content_type => :json).body
    end  
    
    def delete_client(server,token,user_id,client_id)
      RestClient.post("#{server}/api/delete_client",
        {:api_token => token, :user_id => user_id, 
         :client_id => client_id}.to_json, :content_type => :json)    
    end

    def get_client_params(server,token,client_id)
      JSON.parse(RestClient.post("#{server}/api/get_client_params", 
        {:api_token => token, :client_id => client_id}.to_json, :content_type => :json).body)
    end
    
    def list_sources(server,token,partition='all') 
      JSON.parse(RestClient.post("#{server}/api/list_sources", 
        {:api_token => token, :partition_type => partition}.to_json, :content_type => :json).body)
    end

    def get_source_params(server,token,source_id)
      JSON.parse(RestClient.post("#{server}/api/get_source_params", 
        {:api_token => token, :source_id => source_id}.to_json, :content_type => :json).body)
    end
    
    def list_source_docs(server,token,source_id,user_id='*')
      JSON.parse(RestClient.post("#{server}/api/list_source_docs", 
        {:api_token => token, :source_id => source_id, :user_id => user_id}.to_json, :content_type => :json).body)
    end  
      
    def list_client_docs(server,token,source_id,client_id)
      JSON.parse(RestClient.post("#{server}/api/list_client_docs", 
        {:api_token => token, :source_id => source_id, :client_id => client_id}.to_json, :content_type => :json).body)
    end  
    
    #TODO: figure out data_type programmatically     
    def get_db_doc(server,token,doc,data_type='')
      res = RestClient.post("#{server}/api/get_db_doc", 
        {:api_token => token, :doc => doc, :data_type => data_type}.to_json, :content_type => :json).body
      data_type=='' ? JSON.parse(res) : res
    end

    #TODO: figure out data_type programmatically     
    def set_db_doc(server,token,doc,data={},data_type='')
      RestClient.post("#{server}/api/set_db_doc", 
       {:api_token => token, :doc => doc, :data => data, :data_type => data_type}.to_json, :content_type => :json)
    end
          
    def reset(server,token)
      RestClient.post("#{server}/api/reset",
        {:api_token => token}.to_json, :content_type => :json)
    end
    
    def ping(server,token,user_id,params)
      ping_params = {:api_token => token, :user_id => user_id}
      [:message,:badge,:sound,:vibrate,:sources].each do |part|
        ping_params.merge!(part => params[part]) if params[part]
      end
      RestClient.post("#{server}/api/ping",ping_params.to_json, :content_type => :json)
    end

    def get_license_info(server,token)
      JSON.parse(RestClient.post("#{server}/api/get_license_info",
        {:api_token => token}.to_json, :content_type => :json).body)
    end
    
  end
end