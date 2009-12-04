module RhosyncStore
  class ClientSync
    attr_accessor :source,:client,:p_size,:source_sync,:clientdoc
    
    def initialize(source,client,p_size=nil)
      @source,@client,@p_size = source,client,p_size ? p_size : 500
      @source_sync = SourceSync.new(@source)
      @clientdoc = Document.new('cd',@source.app.id,@source.user.id,@client.id,@source.name)
    end
    
    def receive_cud(params)
      params.each do |key,value|
        _receive_cud(key,value)
      end
    end
    
    
    def process(cud_params=nil,query_params=nil)
      #TODO handle ack insert and delete pages
      receive_cud(cud_params) if cud_params
      @source_sync.process(query_params)
    end
    
    def send_cud(token=nil)
      res = resend_page(token)
      return res unless res.empty?
      res['insert'] = compute_page
      res['links'] = @source.app.store.get_data(@clientdoc.get_create_links_dockey)
      res['delete'] = compute_deleted_page
      @source.app.store.put_data(@clientdoc.get_key,res['insert'],true)
      @source.app.store.delete_data(@clientdoc.get_key,res['delete'])
      res.reject! {|key,value| value.nil? or value.empty?}
      res['token'] = compute_token unless res.empty?
      res.merge!(_send_errors)
      res
    end
    
    # Resend token for a client, also sends exceptions
    def resend_page(token=nil)
      res = {}
      if not _ack_token(token)     
        res['insert'] = @source.app.store.get_data(@clientdoc.get_page_dockey)
        res['links'] = @source.app.store.get_data(@clientdoc.get_create_links_dockey)
        res['delete'] = @source.app.store.get_data(@clientdoc.get_delete_page_dockey)
        res.reject! {|key,value| value.nil? or value.empty?}
        res['token'] = @source.app.store.get_value(@clientdoc.get_page_token_dockey) unless res.empty?
        res.merge!(_send_errors)
      end
      res
    end
    
    # Computes diffs between master doc and client doc, trims it to page size, 
    # stores page, and returns page as hash  
    def compute_page
      res = {}
      page_size = @p_size
      @source.app.store.get_diff_data(@clientdoc.get_key,@source.document.get_key).each do |key,item|
        res[key] = item
        page_size -= 1
        break if page_size <= 0         
      end
      @source.app.store.put_data(@clientdoc.get_page_dockey,res)
      res
    end
    
    # Computes deleted objects (down to individual attributes) 
    # in the client documet, trims it to page size, stores page, and returns page as hash      
    def compute_deleted_page
      res = {}
      delete_page_key = @clientdoc.get_delete_page_dockey
      page_size = @p_size
      @source.app.store.get_diff_data(@source.document.get_key,@clientdoc.get_key).each do |key,value|
        res[key] = value
        value.each do |attrib,val|
          @source.app.store.db.sadd(delete_page_key,setelement(key,attrib,val))
        end
        page_size -= 1
        break if page_size <= 0          
      end
      res
    end
    
    # Computes token for a single client request
    def compute_token
      token = _token
      @source.app.store.put_value(@clientdoc.get_page_token_dockey,token)
      token.to_s
    end
    
    # Resets the store for a given app,client
    def self.reset(app,user,client)
      doc = Document.new('cd',app.id,user.id,client.id,'*')
      app.store.get_keys(doc.get_key).each do |key|
        app.store.flash_data(key)
      end
    end
    
    private
    def _receive_cud(operation,params)
      return if not ['create','update','delete'].include?(operation)
      dockey = @source.document.send "get_#{operation}_dockey"
      params.each do |key,value|
        value['rhomobile.rhoclient'] = @client.id.to_s
      end
      @source.app.store.put_data(dockey,params,true)
    end
    
    def _token
      ((Time.now.to_f - Time.mktime(2009,"jan",1,0,0,0,0).to_f) * 10**6).to_i
    end
    
    def _ack_token(token)
      stored_token = @source.app.store.get_value(@clientdoc.get_page_token_dockey)
      if stored_token 
        if token and stored_token == token
          @source.app.store.put_value(@clientdoc.get_page_token_dockey,nil)
          @source.app.store.put_value(@clientdoc.get_create_links_dockey,nil)
          return true
        end
      else
        return true    
      end    
      false
    end
    
    def _send_errors
      res = {}
      ['create','update','delete'].each do |operation|
        res["#{operation}-error"] = @source.app.store.get_data(@clientdoc.send("get_#{operation}_errors_dockey"))
      end
      res["source-error"] = @source.app.store.get_data(@source.document.get_source_errors_dockey)
      res.reject! {|key,value| value.nil? or value.empty?}
      res
    end
  end
end