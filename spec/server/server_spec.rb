require 'rack/test'

require File.join(File.dirname(__FILE__),'..','..','lib','rhosync','server.rb')
require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__), '..', 'support', 'shared_examples')

describe "Server" do
  include Rack::Test::Methods
  include Rhosync

  it_behaves_like "SharedRhosyncHelper", :rhosync_data => true do
    before(:each) do
      require File.join(get_testapp_path,test_app_name)
      Rhosync.bootstrap(get_testapp_path) do |rhosync|
        rhosync.vendor_directory = File.join(rhosync.base_directory,'..','..','..','vendor')
      end      
      Rhosync::Server.set :environment, :test
      Rhosync::Server.set :run, false
      Rhosync::Server.set :secret, "secure!"      

      Rhosync::Server.use Rack::Static, :urls => ["/data"], 
        :root =>  File.expand_path(File.join(File.dirname(__FILE__),'..','apps','rhotestapp'))
    end

    def app
      @app ||= Rhosync::Server.new
    end

    it "should show status page" do
      get '/'
      last_response.body.match(Rhosync::VERSION)[0].should == Rhosync::VERSION
    end

    it "should login without app_name" do
      do_post "/login", "login" => @u_fields[:login], "password" => 'testpass'
      last_response.should be_ok
    end

    it "should login if content-type contains extra parameters" do
      User.load('new_user').should be_nil
      post "/login", {"login" => 'new_user', "password" => 'testpass'}.to_json, {'CONTENT_TYPE'=>'application/json; charset=UTF-8'} 
      last_response.should be_ok
      User.load('new_user').should_not be_nil
    end

    it "should failt to login if wrong content-type" do
      User.load('unknown').should be_nil
      post "/login", {"login" => 'unknown', "password" => 'testpass'}.to_json, {'CONTENT_TYPE'=>'application/x-www-form-urlencoded'} 
      last_response.should be_ok
      User.load('unknown').should be_nil
    end

    it "should login as rhoadmin user" do
      post "/login", "login" => 'rhoadmin', "password" => ''
      last_response.should be_ok
    end

    it "should respond with 401 to /:app_name" do
      get "/application"
      last_response.status.should == 401
    end

    it "should have default session secret" do
      Rhosync::Server.secret.should == "secure!"
    end

    it "should use Stats::Middleware if stats enabled" do
      Rhosync::Server.enable :stats
      Rhosync::Server.new
      Rhosync.stats.should == true
      Rhosync.stats = nil
      Rhosync::Server.disable :stats
    end

    it "should update session secret to default" do
      Rhosync::Server.set :secret, "<changeme>"
      Rhosync::Server.secret.should == "<changeme>"
      Rhosync::Server.should_receive(:log).any_number_of_times.with(any_args())
      check_default_secret!("<changeme>")
      Rhosync::Server.set :secret, "secure!"
    end

    it "should complain about hsqldata.jar missing" do
      Rhosync.vendor_directory = 'missing'
      Rhosync::Server.should_receive(:log).any_number_of_times.with(any_args())
      check_hsql_lib!
    end

    describe "helpers" do 
      before(:each) do
        do_post "/application/clientlogin", "login" => @u.login, "password" => 'testpass'
      end

      it "should return nil if params[:source_name] is missing" do
        get "/application"
        last_response.status.should == 500
      end
    end

    describe "auth routes" do
      it "should login user with correct username,password" do
        do_post "/application/clientlogin", "login" => @u.login, "password" => 'testpass'
        last_response.should be_ok
      end

      it "should return 401 and LoginException messsage from authenticate" do
        do_post "/application/clientlogin", "login" => @u.login, "password" => 'wrongpass'
        last_response.status.should == 401
        last_response.body.should == 'login exception'
      end

      it "should return 500 and Exception messsage from authenticate" do
        do_post "/application/clientlogin", "login" => @u.login, "password" => 'server error'
        last_response.status.should == 500
        last_response.body.should == 'server error'
      end

      it "should return 401 and no messsage from authenticate if no exception raised" do
        do_post "/application/clientlogin", "login" => @u.login, "password" => 'wrongpassnomsg'
        last_response.status.should == 401
        last_response.body.should == ''
      end

      it "should create unknown user through delegated authentication" do
        do_post "/application/clientlogin", "login" => 'newuser', "password" => 'testpass'
        User.is_exist?('newuser').should == true
        @a.users.members.sort.should == ['newuser','testuser']
      end

      it "should create a different username through delegated authentication" do
        do_post "/application/clientlogin", "login" => 'newuser', "password" => 'diffuser'
        User.is_exist?('different').should == true
        @a.users.members.sort.should == ['different','testuser']
      end
    end

    describe "client management routes" do
      before(:each) do
        do_post "/application/clientlogin", "login" => @u.login, "password" => 'testpass'
        @source_config = {
          "sources"=>
          {"FixedSchemaAdapter"=>
            {"poll_interval"=>300,
             "sync_type"=>"incremental",
             "belongs_to"=>[{"brand"=>"SampleAdapter"}]},
           "SampleAdapter"=>{"poll_interval"=>300},
           "SimpleAdapter"=>{"partition_type"=>"app", "poll_interval"=>600}}
        }
      end

      it "should respond to clientcreate" do
        get "/application/clientcreate?device_type=blackberry"
        last_response.should be_ok
        last_response.content_type.should =~ /application\/json/
        id = JSON.parse(last_response.body)['client']['client_id']
        id.length.should == 32
        JSON.parse(last_response.body).should == 
          {"client"=>{"client_id"=>id}}.merge!(@source_config)
        c = Client.load(id,{:source_name => '*'})
        c.user_id.should == 'testuser'
        c.device_type.should == 'blackberry'
      end

      it "should respond to clientregister" do
        do_post "/application/clientregister", 
          "device_type" => "iPhone", "device_pin" => 'abcd', "client_id" => @c.id
        last_response.should be_ok
        JSON.parse(last_response.body).should == @source_config
        @c.device_type.should == 'Apple'
        @c.device_pin.should == 'abcd'
        @c.id.length.should == 32
      end

      it "should respond to clientreset" do
        set_state(@c.docname(:cd) => @data)
        get "/application/clientreset", :client_id => @c.id,:version => ClientSync::VERSION
        JSON.parse(last_response.body).should == @source_config
        verify_result(@c.docname(:cd) => {})
      end

      it "should switch client user if client user_id doesn't match session user" do
        set_test_data('test_db_storage',@data)
        get "/application",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
        JSON.parse(last_response.body).last['insert'].should == @data
        do_post "/application/clientlogin", "login" => 'user2', "password" => 'testpass'
        data = {'1'=>@product1,'2'=>@product2}
        set_test_data('test_db_storage',data)
        get "/application",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
        JSON.parse(last_response.body).last['insert'].should == data
      end
    end

    describe "source routes" do
      before(:each) do
        do_post "/application/clientlogin", "login" => @u.login, "password" => 'testpass'
      end

      it "should return 404 message with version < 3" do
        get "/application",:source_name => @s.name,:version => 2
        last_response.status.should == 404
        last_response.body.should == "Server supports version 3 or higher of the protocol."
      end

      it "should post records for create" do
        @product1['_id'] = '1'
        params = {'create'=>{'1'=>@product1},:client_id => @c.id,:source_name => @s.name,
          :version => ClientSync::VERSION}
        do_post "/application", params
        last_response.should be_ok
        last_response.body.should == ''
        verify_result("test_create_storage" => {'1'=>@product1})
      end

      it "should post records for update" do
        params = {'update'=>{'1'=>@product1},:client_id => @c.id,:source_name => @s.name,
          :version => ClientSync::VERSION}
        do_post "/application", params
        last_response.should be_ok
        last_response.body.should == ''
        verify_result("test_update_storage" => {'1'=>@product1})
      end

      it "should post records for delete" do
        params = {'delete'=>{'1'=>@product1},:client_id => @c.id,:source_name => @s.name,
          :version => ClientSync::VERSION}
        do_post "/application", params
        last_response.should be_ok
        last_response.body.should == ''
        verify_result("test_delete_storage" => {'1'=>@product1})
      end

      it "should handle client posting broken json" do
        broken_json = "{\"foo\":\"bar\"\"}"
        post "/application", broken_json, {'CONTENT_TYPE'=>'application/json'}
        last_response.status.should == 500
        last_response.body.should == "Server error while processing client data"
      end

      it "should handle client posting broken body" do
        broken_json = ['foo']
        post "/application", broken_json, {'CONTENT_TYPE'=>'application/json'}
        last_response.status.should == 500
        last_response.body.should == "Internal server error"
      end

      it "should get inserts json" do
        cs = ClientSync.new(@s,@c,1)
        data = {'1'=>@product1,'2'=>@product2}
        set_test_data('test_db_storage',data)
        get "/application",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
        last_response.should be_ok
        last_response.content_type.should =~ /application\/json/
        token = @c.get_value(:page_token)
        JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
          {"count"=>2}, {"progress_count"=>0},{"total_count"=>2},{'insert'=>data}]
      end

      it "should get inserts json and confirm token" do
        cs = ClientSync.new(@s,@c,1)
        data = {'1'=>@product1,'2'=>@product2}
        set_test_data('test_db_storage',data)
        get "/application",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
        last_response.should be_ok
        token = @c.get_value(:page_token)
        JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
          {"count"=>2}, {"progress_count"=>0}, {"total_count"=>2},{'insert'=>data}]
        get "/application",:client_id => @c.id,:source_name => @s.name,:token => token,
          :version => ClientSync::VERSION
        last_response.should be_ok
        JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>''}, 
          {"count"=>0}, {"progress_count"=>2}, {"total_count"=>2},{}]
      end

      it "should return error if source_name is unknown" do
        get "/application",:client_id => @c.id,:source_name => 'Broken',:version => ClientSync::VERSION
        last_response.status.should == 500
        last_response.body.should == "ERROR: Source 'Broken' requested by client doesn't exist.\n"
      end

      it "should get deletes json" do
        cs = ClientSync.new(@s,@c,1)
        data = {'1'=>@product1,'2'=>@product2}
        set_test_data('test_db_storage',data)

        get "/application",:client_id => @c.id,:source_name => @s.name,:version => ClientSync::VERSION
        last_response.should be_ok
        token = @c.get_value(:page_token)
        JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
          {"count"=>2}, {"progress_count"=>0}, {"total_count"=>2},{'insert'=>data}]

        Store.flash_data('test_db_storage')
        @s.read_state.refresh_time = Time.now.to_i      

        get "/application",:client_id => @c.id,:source_name => @s.name,:token => token,
          :version => ClientSync::VERSION
        last_response.should be_ok
        token = @c.get_value(:page_token)
        JSON.parse(last_response.body).should == [{"version"=>ClientSync::VERSION},{"token"=>token}, 
          {"count"=>2}, {"progress_count"=>0}, {"total_count"=>0},{'delete'=>data}]
      end

      it "should get search results" do
        sources = [{:name=>'SampleAdapter'}]
        cs = ClientSync.new(@s,@c,1)
        Store.put_data('test_db_storage',@data)
        params = {:client_id => @c.id,:sources => sources,:search => {'name' => 'iPhone'},
          :version => ClientSync::VERSION}
        get "/application/search",params
        last_response.content_type.should =~ /application\/json/
        token = @c.get_value(:search_token)
        JSON.parse(last_response.body).should == [[{'version'=>ClientSync::VERSION},{'token'=>token},
          {'source'=>sources[0][:name]},{'count'=>1},{'insert'=>{'1'=>@product1}}]]
      end

      it "should get search results with error" do
        sources = [{:name=>'SampleAdapter'}]
        msg = "Error during search"
        error = set_test_data('test_db_storage',@data,msg,'search error')
        params = {:client_id => @c.id,:sources => sources,:search => {'name' => 'iPhone'},
          :version => ClientSync::VERSION}
        get "/application/search",params
        JSON.parse(last_response.body).should == [[{'version'=>ClientSync::VERSION},
          {'source'=>sources[0][:name]},{'search-error'=>{'search-error'=>{'message'=>msg}}}]]
      end

      it "should get multiple source search results" do
        Store.put_data('test_db_storage',@data)
        sources = [{:name=>'SimpleAdapter'},{:name=>'SampleAdapter'}]
        params = {:client_id => @c.id,:sources => sources,:search => {'search' => 'bar'},
          :version => ClientSync::VERSION}
        get "/application/search",params
        @c.source_name = 'SimpleAdapter'
        token1 = @c.get_value(:search_token)
        @c.source_name = 'SampleAdapter'
        token = @c.get_value(:search_token)
        JSON.parse(last_response.body).should == [
          [{"version"=>ClientSync::VERSION},{'token'=>token1},{"source"=>"SimpleAdapter"}, 
           {"count"=>1}, {"insert"=>{'obj'=>{'foo'=>'bar'}}}],
          [{"version"=>ClientSync::VERSION},{'token'=>token},{"source"=>"SampleAdapter"}, 
           {"count"=>1}, {"insert"=>{'1'=>@product1}}]]
      end
    end

    describe "bulk data routes" do
      before(:each) do
        do_post "/application/clientlogin", "login" => @u.login, "password" => 'testpass'
      end

      after(:each) do
        delete_data_directory
      end

      it "should make initial bulk data request and receive wait" do
        set_state('test_db_storage' => @data)
        get "/application/bulk_data", :partition => :user, :client_id => @c.id
        last_response.should be_ok
        last_response.body.should == {:result => :wait}.to_json
      end

      it "should receive url when bulk data is available" do
        set_state('test_db_storage' => @data)
        get "/application/bulk_data", :partition => :user, :client_id => @c.id
        BulkDataJob.perform("data_name" => bulk_data_docname(@a.id,@u.id))
        get "/application/bulk_data", :partition => :user, :client_id => @c.id
        last_response.should be_ok
        data = BulkData.load(bulk_data_docname(@a.id,@u.id))
        last_response.body.should == {:result => :url, 
          :url => data.url}.to_json
        validate_db(data,{@s.name => @data, 'FixedSchemaAdapter' => @data})
      end

      it "should download bulk data file" do
        set_state('test_db_storage' => @data)
        get "/application/bulk_data", :partition => :user, :client_id => @c.id
        BulkDataJob.perform("data_name" => bulk_data_docname(@a.id,@u.id))
        get "/application/bulk_data", :partition => :user, :client_id => @c.id
        get JSON.parse(last_response.body)["url"]
        last_response.should be_ok
        File.open('test.data','wb') {|f| f.puts last_response.body}
        validate_db_file('test.data',[@s.name,'FixedSchemaAdapter'],{@s.name => @data, 'FixedSchemaAdapter' => @data})
        File.delete('test.data')
      end

      it "should receive nop when no sources are available for partition" do
        set_state('test_db_storage' => @data)
        Source.load('SimpleAdapter',@s_params).partition = :user
        get "/application/bulk_data", :partition => :app, :client_id => @c.id
        last_response.should be_ok
        last_response.body.should == {:result => :nop}.to_json
      end
    end

    describe "blob sync" do
      before(:each) do
        do_post "/application/clientlogin", "login" => @u.login, "password" => 'testpass'
      end
      it "should upload blob in multipart post" do
        file1,file2 = 'upload1.txt','upload2.txt'
        @product1['txtfile-rhoblob'] = file1
        @product1['_id'] = 'tempobj1'
        @product2['txtfile-rhoblob'] = file2
        @product2['_id'] = 'tempobj2'
        cud = {'create'=>{'1'=>@product1,'2'=>@product2},
          :client_id => @c.id,:source_name => @s.name,
          :version => ClientSync::VERSION,
          :blob_fields => ['txtfile-rhoblob']}.to_json
        post "/application", 
          {:cud => cud,'txtfile-rhoblob-1' => 
            Rack::Test::UploadedFile.new(File.join(File.dirname(__FILE__),'..','testdata',file1), "application/octet-stream"),
            'txtfile-rhoblob-2' => 
              Rack::Test::UploadedFile.new(File.join(File.dirname(__FILE__),'..','testdata',file2), "application/octet-stream")}
        Store.get_data('test_create_storage').each do |id,obj|
          File.exists?(obj['txtfile-rhoblob']).should == true
        end
      end
    end
  end
end