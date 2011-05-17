require File.join(File.dirname(__FILE__),'..','..','lib','rhosync','console','rhosync_api.rb')
require File.join(File.dirname(__FILE__),'api_helper')

describe "RhosyncApi" do
  it_should_behave_like "ApiHelper" do
  
  it "should return api token using direct api call" do
    RhosyncApi::get_token('','rhoadmin','').should == @api_token
  end
  
  it "should return api token using rest call" do
    response = {'set-cookie'=>"rhosync_session=c21...42b64; path=/; expires=Tue, 02-Aug-2011 23:55:19 GMT"}
    res = mock('HttpResponse')
    res.stub!(:response).and_return(response)
    http = mock('NetHttp')
    http.stub!(:post).and_return(res)
    Net::HTTP.stub!(:new).and_return(http)
    RestClient.stub(:post).and_return(@api_token)
    
    Net::HTTP.should_receive(:new).once
    RestClient.should_receive(:post).once
    RhosyncApi::get_token('some_url','rhoadmin','').should == @api_token
  end
  
  it "should list users using direct api call" do
    RhosyncApi::list_users('',@api_token).should == ['testuser']
  end
  
  it "should list users using rect call" do
    res = mock('HttpResponse')
    res.stub!(:body).and_return(['testuser'].to_json)
    RestClient.stub(:post).and_return(res)
    RestClient.should_receive(:post).once
    RhosyncApi::list_users('some_url',@api_token).should == ['testuser']
  end
  
  it "should create user using direct api call" do
    RhosyncApi::create_user('',@api_token,'testuser1','testpass1')
    User.load('testuser1').login.should == 'testuser1'
    User.authenticate('testuser1','testpass1').login.should == 'testuser1'
    @a.users.members.sort.should == [@u.login, 'testuser1']    
  end 
  
  it "should create user using rect call" do
    RestClient.stub(:post).and_return("User created")
    RestClient.should_receive(:post).once
    RhosyncApi::create_user('some_url',@api_token,'testuser1','testpass1').should == "User created"
  end
  
  it "should update user using direct api call" do
    RhosyncApi::update_user('',@api_token, {:new_password => '123'})
    User.authenticate('rhoadmin','123').login.should == 'rhoadmin'
  end
      
  it "should return api token using rest call" do
    response = {'set-cookie'=>"rhosync_session=c21...42b64; path=/; expires=Tue, 02-Aug-2011 23:55:19 GMT"}
    res = mock('HttpResponse')
    res.stub!(:response).and_return(response)
    http = mock('NetHttp')
    http.stub!(:post).and_return(res)
    Net::HTTP.stub!(:new).and_return(http)
    RestClient.stub(:post).and_return(@api_token)

    Net::HTTP.should_receive(:new).once
    RestClient.should_receive(:post).once
    RhosyncApi::get_token('some_url','rhoadmin','').should == @api_token
  end

  it "should delete user using rect call" do
    RestClient.stub(:post).and_return("User deleted")
    RestClient.should_receive(:post).once
    RhosyncApi::delete_user('some_url',@api_token,'testuser1').should == "User deleted"
  end
  
  it "should list clients using direct api call" do
    res = RhosyncApi::list_clients('',@api_token,@u_fields[:login])
    res.is_a?(Array).should == true
    res.size.should == 1
    res[0].is_a?(String) == true
    res[0].length.should == 32
  end
  
  it "should handle empty client's list" do
    @u.clients.delete(@c.id)
    RhosyncApi::list_clients('',@api_token,@u_fields[:login]).should == []
  end  
  
  it "should create user using rect call" do
    res = mock('HttpResponse')
    res.stub!(:body).and_return(["21325fd9911044c6ad974785bf23c173"].to_json)
    RestClient.stub(:post).and_return(res)    
    RestClient.should_receive(:post).once
    RhosyncApi::list_clients('some_url',@api_token,'testuser1').should == ["21325fd9911044c6ad974785bf23c173"]
  end
  
  it "should create client for a user using direct api call" do
    RhosyncApi::create_client('',@api_token,@u_fields[:login])
    clients = User.load(@u_fields[:login]).clients.members
    clients.size.should == 2
  end  
  
  it "should create client using rect call" do
    res = mock('HttpResponse')
    res.stub!(:body).and_return("")
    RestClient.stub(:post).and_return(res)    
    RestClient.should_receive(:post).once
    RhosyncApi::create_client('some_url',@api_token,'testuser1')
  end
  
  it "should delete client using direct api call" do
    RhosyncApi::delete_client('',@api_token,@u_fields[:login],@c.id).should == "Client deleted"
    Client.is_exist?(@c.id).should == false
    User.load(@u_fields[:login]).clients.members.should == []
  end
  
  it "should delete client using rect call" do
    RestClient.stub(:post).and_return("Client deleted")
    RestClient.should_receive(:post).once
    RhosyncApi::delete_client('some_url',@api_token,@u_fields[:login],@c.id).should == "Client deleted"
  end
  
  it "should list client attributes using direct api call" do
    res = RhosyncApi::get_client_params('',@api_token,@c.id)
    res.delete_if { |attrib| attrib['name'] == 'rho__id' }
    res.sort{|x,y| x['name']<=>y['name']}.should == [
      {"name"=>"device_type", "value"=>"Apple", "type"=>"string"}, 
      {"name"=>"device_pin", "value"=>"abcd", "type"=>"string"}, 
      {"name"=>"device_port", "value"=>"3333", "type"=>"string"}, 
      {"name"=>"user_id", "value"=>"testuser", "type"=>"string"}, 
      {"name"=>"app_id", "value"=>"application", "type"=>"string"}].sort{|x,y| x['name']<=>y['name']}
  end
  
  it "should list client attributes using rest call" do
    res = mock('HttpResponse')
    res.stub!(:body).and_return(["blah"].to_json)
    RestClient.stub(:post).and_return(res)    
    RestClient.should_receive(:post).once
    RhosyncApi::get_client_params('some_url',@api_token,'client_id')  
  end
  
  it "should list all application sources using direct api call" do
    RhosyncApi::list_sources('',@api_token).sort.should == 
      ["SimpleAdapter", "SampleAdapter", "FixedSchemaAdapter"].sort
  end  
  
  it "should list all application sources using rest call" do
    res = mock('HttpResponse')
    res.stub!(:body).and_return(["SimpleAdapter", "SampleAdapter", "FixedSchemaAdapter"].to_json)
    RestClient.stub(:post).and_return(res)    
    RestClient.should_receive(:post).once
    RhosyncApi::list_sources('some_url',@api_token)
  end
  
  it "should list source attributes using direct api call" do
    RhosyncApi::get_source_params('',@api_token,"SampleAdapter").should == [
      {"name"=>"rho__id", "value"=>"SampleAdapter", "type"=>"string"}, 
      {"name"=>"foo_id", "value"=>nil, "type"=>"string"}]        
#      {"name"=>"source_id", "value"=>nil, "type"=>"integer"}, 
#      {"name"=>"name", "value"=>"SampleAdapter", "type"=>"string"}, 
#      {"name"=>"url", "value"=>"", "type"=>"string"}, 
#      {"name"=>"login", "value"=>"", "type"=>"string"}, 
#      {"name"=>"password", "value"=>"", "type"=>"string"}, 
#      {"name"=>"priority", "value"=>3, "type"=>"integer"}, 
#      {"name"=>"callback_url", "value"=>nil, "type"=>"string"}, 
#      {"name"=>"poll_interval", "value"=>300, "type"=>"integer"}, 
#      {"name"=>"partition_type", "value"=>"user", "type"=>"string"}, 
#      {"name"=>"sync_type", "value"=>"incremental", "type"=>"string"}, 
#      {"name"=>"belongs_to", "type"=>"string", "value"=>nil},
#      {"name"=>"has_many", "type"=>"string", "value"=>"FixedSchemaAdapter,brand"},
#      {"name"=>"queue", "value"=>nil, "type"=>"string"}, 
#      {"name"=>"query_queue", "value"=>nil, "type"=>"string"}, 
#      {"name"=>"cud_queue", "value"=>nil, "type"=>"string"},
#      {"name"=>"pass_through", "value"=>nil, "type"=>"string"}]
  end
 
  it "should list source attributes using rest call" do
    res = mock('HttpResponse')
    res.stub!(:body).and_return(["SimpleAdapter"].to_json)
    RestClient.stub(:post).and_return(res)    
    RestClient.should_receive(:post).once
    RhosyncApi::get_source_params('some_url',@api_token,"SimpleAdapter")
  end
  
  it "should list of shared source documents using direct api call" do
    RhosyncApi::list_source_docs('',@api_token,"SimpleAdapter","*").sort.should == {
      "md"=>"source:application:__shared__:SimpleAdapter:md", 
      "errors"=>"source:application:__shared__:SimpleAdapter:errors", 
      "md_size"=>"source:application:__shared__:SimpleAdapter:md_size", 
      "md_copy"=>"source:application:__shared__:SimpleAdapter:md_copy"}.sort
  end
  
  it "should list of shared source documents using rest call" do
    res = mock('HttpResponse')
    res.stub!(:body).and_return(["SimpleAdapter"].to_json)
    RestClient.stub(:post).and_return(res)    
    RestClient.should_receive(:post).once
    RhosyncApi::list_source_docs('some_url',@api_token,"SimpleAdapter",'*')
  end
  
  it "should list client documents using direct api call" do
    RhosyncApi::list_client_docs('',@api_token,"SimpleAdapter",@c.id).should == {
      "cd"=>"client:application:testuser:#{@c.id}:SimpleAdapter:cd", 
      "cd_size"=>"client:application:testuser:#{@c.id}:SimpleAdapter:cd_size", 
      "create"=>"client:application:testuser:#{@c.id}:SimpleAdapter:create", 
      "update"=>"client:application:testuser:#{@c.id}:SimpleAdapter:update", 
      "delete"=>"client:application:testuser:#{@c.id}:SimpleAdapter:delete", 

      "page"=>"client:application:testuser:#{@c.id}:SimpleAdapter:page", 
      "page_token"=>"client:application:testuser:#{@c.id}:SimpleAdapter:page_token", 
      "delete_page"=>"client:application:testuser:#{@c.id}:SimpleAdapter:delete_page", 
      "create_links"=>"client:application:testuser:#{@c.id}:SimpleAdapter:create_links", 
      "create_links_page"=>"client:application:testuser:#{@c.id}:SimpleAdapter:create_links_page", 

      "delete_errors"=>"client:application:testuser:#{@c.id}:SimpleAdapter:delete_errors", 
      "login_error"=>"client:application:testuser:#{@c.id}:SimpleAdapter:login_error", 
      "create_errors"=>"client:application:testuser:#{@c.id}:SimpleAdapter:create_errors", 
      "update_errors"=>"client:application:testuser:#{@c.id}:SimpleAdapter:update_errors", 
      "logoff_error"=>"client:application:testuser:#{@c.id}:SimpleAdapter:logoff_error", 

      "search"=>"client:application:testuser:#{@c.id}:SimpleAdapter:search",
      "search_token"=>"client:application:testuser:#{@c.id}:SimpleAdapter:search_token", 
      "search_errors"=>"client:application:testuser:#{@c.id}:SimpleAdapter:search_errors"}
    end

    it "should list users using direct api call" do
      RhosyncApi::list_users('',@api_token).should == ['testuser']
    end

    it "should list users using rect call" do
      res = mock('HttpResponse')
      res.stub!(:body).and_return(['testuser'].to_json)
      RestClient.stub(:post).and_return(res)
      RestClient.should_receive(:post).once
      RhosyncApi::list_users('some_url',@api_token).should == ['testuser']
    end

    it "should create user using direct api call" do
      RhosyncApi::create_user('',@api_token,'testuser1','testpass1')
      User.load('testuser1').login.should == 'testuser1'
      User.authenticate('testuser1','testpass1').login.should == 'testuser1'
      @a.users.members.sort.should == [@u.login, 'testuser1']    
    end 

    it "should create user using rect call" do
      RestClient.stub(:post).and_return("User created")
      RestClient.should_receive(:post).once
      RhosyncApi::create_user('some_url',@api_token,'testuser1','testpass1').should == "User created"
    end

    it "should update user using direct api call" do
      RhosyncApi::update_user('',@api_token, {:new_password => '123'})
      User.authenticate('rhoadmin','123').login.should == 'rhoadmin'
    end

    it "should update user using rest call" do
      RestClient.stub(:post)    
      RestClient.should_receive(:post).once
      RhosyncApi::update_user('some_url',@api_token, {:new_password => '123'})
    end

    it "should delete user direct api call" do
      RhosyncApi::create_user('',@api_token,'testuser1','testpass1').should == "User created"
      User.is_exist?('testuser1').should == true
      RhosyncApi::delete_user('',@api_token,'testuser1').should == "User deleted"
      User.is_exist?('testuser1').should == false
      App.load(test_app_name).users.members.should == ["testuser"]
    end

    it "should delete user using rect call" do
      RestClient.stub(:post).and_return("User deleted")
      RestClient.should_receive(:post).once
      RhosyncApi::delete_user('some_url',@api_token,'testuser1').should == "User deleted"
    end

    it "should list clients using direct api call" do
      res = RhosyncApi::list_clients('',@api_token,@u_fields[:login])
      res.is_a?(Array).should == true
      res.size.should == 1
      res[0].is_a?(String) == true
      res[0].length.should == 32
    end

    it "should handle empty client's list" do
      @u.clients.delete(@c.id)
      RhosyncApi::list_clients('',@api_token,@u_fields[:login]).should == []
    end  

    it "should create user using rect call" do
      res = mock('HttpResponse')
      res.stub!(:body).and_return(["21325fd9911044c6ad974785bf23c173"].to_json)
      RestClient.stub(:post).and_return(res)    
      RestClient.should_receive(:post).once
      RhosyncApi::list_clients('some_url',@api_token,'testuser1').should == ["21325fd9911044c6ad974785bf23c173"]
    end

    it "should create client for a user using direct api call" do
      RhosyncApi::create_client('',@api_token,@u_fields[:login])
      clients = User.load(@u_fields[:login]).clients.members
      clients.size.should == 2
    end  

    it "should create client using rect call" do
      res = mock('HttpResponse')
      res.stub!(:body).and_return("")
      RestClient.stub(:post).and_return(res)    
      RestClient.should_receive(:post).once
      RhosyncApi::create_client('some_url',@api_token,'testuser1')
    end

    it "should delete client using direct api call" do
      RhosyncApi::delete_client('',@api_token,@u_fields[:login],@c.id).should == "Client deleted"
      Client.is_exist?(@c.id).should == false
      User.load(@u_fields[:login]).clients.members.should == []
    end

    it "should delete client using rect call" do
      RestClient.stub(:post).and_return("Client deleted")
      RestClient.should_receive(:post).once
      RhosyncApi::delete_client('some_url',@api_token,@u_fields[:login],@c.id).should == "Client deleted"
    end

    it "should list client attributes using direct api call" do
      res = RhosyncApi::get_client_params('',@api_token,@c.id)
      res.delete_if { |attrib| attrib['name'] == 'rho__id' }
      res.sort{|x,y| x['name']<=>y['name']}.should == [
        {"name"=>"device_type", "value"=>"Apple", "type"=>"string"}, 
        {"name"=>"device_pin", "value"=>"abcd", "type"=>"string"}, 
        {"name"=>"device_port", "value"=>"3333", "type"=>"string"}, 
        {"name"=>"user_id", "value"=>"testuser", "type"=>"string"}, 
        {"name"=>"app_id", "value"=>"application", "type"=>"string"}].sort{|x,y| x['name']<=>y['name']}
    end

    it "should list client attributes using rest call" do
      res = mock('HttpResponse')
      res.stub!(:body).and_return(["blah"].to_json)
      RestClient.stub(:post).and_return(res)    
      RestClient.should_receive(:post).once
      RhosyncApi::get_client_params('some_url',@api_token,'client_id')  
    end

    it "should list all application sources using direct api call" do
      RhosyncApi::list_sources('',@api_token).sort.should == 
        ["SimpleAdapter", "SampleAdapter", "FixedSchemaAdapter"].sort
    end  

    it "should list all application sources using rest call" do
      res = mock('HttpResponse')
      res.stub!(:body).and_return(["SimpleAdapter", "SampleAdapter", "FixedSchemaAdapter"].to_json)
      RestClient.stub(:post).and_return(res)    
      RestClient.should_receive(:post).once
      RhosyncApi::list_sources('some_url',@api_token)
    end

    it "should list source attributes using direct api call" do
      RhosyncApi::get_source_params('',@api_token,"SampleAdapter").should == [
        {"name"=>"rho__id", "value"=>"SampleAdapter", "type"=>"string"},
        {"name"=>"foo_id", "value"=>nil, "type"=>"string"}]
#           
#        {"name"=>"source_id", "value"=>nil, "type"=>"integer"}, 
#        {"name"=>"name", "value"=>"SampleAdapter", "type"=>"string"}, 
#        {"name"=>"url", "value"=>"", "type"=>"string"}, 
#        {"name"=>"login", "value"=>"", "type"=>"string"}, 
#        {"name"=>"password", "value"=>"", "type"=>"string"}, 
#        {"name"=>"priority", "value"=>3, "type"=>"integer"}, 
#        {"name"=>"callback_url", "value"=>nil, "type"=>"string"}, 
#        {"name"=>"poll_interval", "value"=>300, "type"=>"integer"}, 
#        {"name"=>"partition_type", "value"=>"user", "type"=>"string"}, 
#        {"name"=>"sync_type", "value"=>"incremental", "type"=>"string"}, 
#        {"name"=>"belongs_to", "type"=>"string", "value"=>nil},
#        {"name"=>"has_many", "type"=>"string", "value"=>"FixedSchemaAdapter,brand"},
#        {"name"=>"queue", "value"=>nil, "type"=>"string"}, 
#        {"name"=>"query_queue", "value"=>nil, "type"=>"string"}, 
#        {"name"=>"cud_queue", "value"=>nil, "type"=>"string"},
#        {"name"=>"pass_through", "value"=>nil, "type"=>"string"}]
    end

    it "should list source attributes using rest call" do
      res = mock('HttpResponse')
      res.stub!(:body).and_return(["SimpleAdapter"].to_json)
      RestClient.stub(:post).and_return(res)    
      RestClient.should_receive(:post).once
      RhosyncApi::get_source_params('some_url',@api_token,"SimpleAdapter")
    end

    it "should list of shared source documents using direct api call" do
      RhosyncApi::list_source_docs('',@api_token,"SimpleAdapter","*").sort.should == {
        "md"=>"source:application:__shared__:SimpleAdapter:md", 
        "errors"=>"source:application:__shared__:SimpleAdapter:errors", 
        "md_size"=>"source:application:__shared__:SimpleAdapter:md_size", 
        "md_copy"=>"source:application:__shared__:SimpleAdapter:md_copy"}.sort
    end

    it "should list of shared source documents using rest call" do
      res = mock('HttpResponse')
      res.stub!(:body).and_return(["SimpleAdapter"].to_json)
      RestClient.stub(:post).and_return(res)    
      RestClient.should_receive(:post).once
      RhosyncApi::list_source_docs('some_url',@api_token,"SimpleAdapter",'*')
    end

    it "should list client documents using direct api call" do
      RhosyncApi::list_client_docs('',@api_token,"SimpleAdapter",@c.id).should == {
        "cd"=>"client:application:testuser:#{@c.id}:SimpleAdapter:cd", 
        "cd_size"=>"client:application:testuser:#{@c.id}:SimpleAdapter:cd_size", 
        "create"=>"client:application:testuser:#{@c.id}:SimpleAdapter:create", 
        "update"=>"client:application:testuser:#{@c.id}:SimpleAdapter:update", 
        "delete"=>"client:application:testuser:#{@c.id}:SimpleAdapter:delete", 

        "page"=>"client:application:testuser:#{@c.id}:SimpleAdapter:page", 
        "page_token"=>"client:application:testuser:#{@c.id}:SimpleAdapter:page_token", 
        "delete_page"=>"client:application:testuser:#{@c.id}:SimpleAdapter:delete_page", 
        "create_links"=>"client:application:testuser:#{@c.id}:SimpleAdapter:create_links", 
        "create_links_page"=>"client:application:testuser:#{@c.id}:SimpleAdapter:create_links_page", 

        "delete_errors"=>"client:application:testuser:#{@c.id}:SimpleAdapter:delete_errors", 
        "login_error"=>"client:application:testuser:#{@c.id}:SimpleAdapter:login_error", 
        "create_errors"=>"client:application:testuser:#{@c.id}:SimpleAdapter:create_errors", 
        "update_errors"=>"client:application:testuser:#{@c.id}:SimpleAdapter:update_errors", 
        "logoff_error"=>"client:application:testuser:#{@c.id}:SimpleAdapter:logoff_error", 

        "search"=>"client:application:testuser:#{@c.id}:SimpleAdapter:search",
        "search_token"=>"client:application:testuser:#{@c.id}:SimpleAdapter:search_token", 
        "search_errors"=>"client:application:testuser:#{@c.id}:SimpleAdapter:search_errors"}
    end

    it "should list client documents using rest call" do
      res = mock('HttpResponse')
      res.stub!(:body).and_return(["SimpleAdapter"].to_json)
      RestClient.stub(:post).and_return(res)    
      RestClient.should_receive(:post).once
      RhosyncApi::list_client_docs('some_url',@api_token,"SimpleAdapter",'*')
    end

    it "should return db document by name using direct api call" do
      data = {'1' => {'foo' => 'bar'}}
      set_state('abc:abc' => data)
      RhosyncApi::get_db_doc('',@api_token,'abc:abc').should == data
    end

    it "should return db document by name and data_type using direct api call" do
      data = 'some string'
      set_state('abc:abc' => data)
      RhosyncApi::get_db_doc('',@api_token,'abc:abc','string').should == data
    end    

    it "should return db document using rest call" do
      data = 'some string'
      res = mock('HttpResponse')
      res.stub!(:body).and_return(data)
      RestClient.stub(:post).and_return(res)    
      RestClient.should_receive(:post).once
      RhosyncApi::get_db_doc('some_url',@api_token,'abc:abc','string').should == data
    end  

    it "should set db document by doc name and data using direct api call" do
      data = {'1' => {'foo' => 'bar'}}
      RhosyncApi::set_db_doc('',@api_token,'abc:abc',data)
      verify_result('abc:abc' => data)
    end

    it "should set db document by doc name, data type, and data using direct api call" do
      data = 'some string'
      RhosyncApi::set_db_doc('',@api_token,'abc:abc:str',data,'string')
      verify_result('abc:abc:str' => data)
    end

    it "should set db document using rest call" do
      data = 'some string'
      RestClient.stub(:post)    
      RestClient.should_receive(:post).once
      RhosyncApi::set_db_doc('some_url',@api_token,'abc:abc:str',data,'string')
    end  

    it "should reset and re-create rhoadmin user with bootstrap using direct api call" do
      Store.put_data('somedoc',{'foo'=>'bar'})
      RhosyncApi::reset('',@api_token).should == "DB reset"
      App.is_exist?(test_app_name).should == true
      Store.get_data('somedoc').should == {}
      User.authenticate('rhoadmin','').should_not be_nil
    end

    it "should reset db using rest call" do
      RestClient.stub(:post).and_return("DB reset")    
      RestClient.should_receive(:post).once
      RhosyncApi::reset('some_url',@api_token).should == "DB reset"
    end

    it "should do ping asynchronously using direct api call" do
      params = {"user_id" => @u.id, "api_token" => @api_token, 
        "async" => "true","sources" => [@s.name], "message" => 'hello world', 
        "vibrate" => '5', "badge" => '5', "sound" => 'hello.mp3'}
      PingJob.should_receive(:enqueue).once.with(params)
      RhosyncApi::ping('',@api_token,@u.id,params)
    end

    it "should do ping using rest call" do
      RestClient.stub(:post)    
      RestClient.should_receive(:post).once
      RhosyncApi::ping('some_url',@api_token,@u.id,{})
    end

    it "should get license info using direct api call" do
      RhosyncApi::get_license_info('',@api_token).should == {
        "available" => 9, 
        "issued" => "Fri Apr 23 17:20:13 -0700 2010", 
        "seats" => 10, 
        "rhosync_version" => "Version 1",
        "licensee" => "Rhomobile" }
    end 

    it "should get license info using rest call" do
      res = mock('HttpResponse')
      res.stub!(:body).and_return(['data'].to_json)
      RestClient.stub(:post).and_return(res)    
      RestClient.should_receive(:post).once
      RhosyncApi::get_license_info('some_url',@api_token)
    end

    it "should get stats using direct api call" do
      Rhosync.stats = true
      Store.set_value('stat:foo','bar')
      RhosyncApi::stats('',@api_token,:metric => 'foo').should == 'bar'
      Rhosync.stats = false
    end

    it "should get stats using rest call" do
      res = mock('HttpResponse')
      res.stub!(:body).and_return('bar')
      RestClient.stub(:post).and_return(res)
      RestClient.should_receive(:post).once.and_return(res)
      RhosyncApi::stats('some_url',@api_token,:metric => 'foo')
    end
  end  
end  