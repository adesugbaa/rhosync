require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), 'support', 'shared_examples')

describe "Source" do
  it_behaves_like "SharedRhosyncHelper", :rhosync_data => false do
    it "should create and load source with @s_fields and @s_params" do
      @s.name.should == @s_fields[:name]
      @s.url.should == @s_fields[:url]
      @s.login.should == @s_fields[:login]
      @s.app.name.should == @a_fields[:name]
      @s.priority.should == 3
      @s.callback_url.should be_nil
      @s.queue.should be_nil
      @s.query_queue.should be_nil
      @s.cud_queue.should be_nil
      @s.app_id.should == @s_params[:app_id]
      @s.user_id.should == @s_params[:user_id]
      @s.sync_type.should == "incremental" #:incremental
      @s.partition_type.should == "user"   #:user
      @s.poll_interval.should == 300

      @s1 = Source.load(@s.id,@s_params)
      @s1.name.should == @s_fields[:name]
      @s1.url.should == @s_fields[:url]
      @s1.login.should == @s_fields[:login]
      @s1.app.name.should == @a_fields[:name]
      @s1.priority.should == 3
      @s1.callback_url.should be_nil
      @s1.poll_interval.should == 300
      @s1.app_id.should == @s_params[:app_id]
      @s1.user_id.should == @s_params[:user_id]
    end

    it "should create source with user" do
      @s.user.login.should == @u_fields[:login]
    end

    it "should create source with app and document" do
      @s.app.name.should == @a_fields[:name]
      @s.docname(:md).should == "source:#{@s.app.id}:#{@u.id}:#{@s_fields[:name]}:md"
    end

    it "should delete source" do
      @s.delete
      Source.is_exist?(@s_fields[:name]).should == false
    end

    it "should delete master and all documents associated with source" do
      set_state(@s.docname(:md) => @data)
      @s.delete
      verify_result(@s.docname(:md) => {})
      Store.db.keys(@s.docname('*')).should == []
    end

    it "should create source with default partition user" do
      @s1 = Source.load(@s_fields[:name],{:app_id => @a.id,:user_id => '*'})
      @s1.partition.should == :user
    end

    it "should create correct docname based on partition scheme" do
      @s.partition = :app
      @s.docname(:md).should == "source:#{@s.app.id}:__shared__:#{@s_fields[:name]}:md"
    end

    it "should create source with default read/write queue" do
      @s.delete
      @s_fields[:queue] = 'default' #:default
      @s_fields[:query_queue] = 'query' #:query
      @s_fields[:cud_queue] = 'cud' #:cud
      Source.create(@s_fields,@s_params)
      s = Source.load(@s_fields[:name],@s_params)
      s.queue.should == 'default'
      s.query_queue.should == 'query'
      s.cud_queue.should == 'cud'
    end

    it "should add associations based on belongs_to field for a source" do
      @s2 = Source.create({:name => 'SimpleAdapter'}, @s_params)
      @s2.belongs_to = [{'product_id' => 'SampleAdapter'}].to_json
      Source.update_associations([@s.name,@s1.name, @s2.name])
      s = Source.load(@s.name,{:app_id => @a.id,:user_id => '*'})
      s.has_many.should == "#{@s1.name},brand,#{@s2.name},product_id"
    end

    it "should log warning about incorrect belongs_to format for a source" do
      @s2 = Source.create({:name => 'SimpleAdapter'}, @s_params)
      @s2.belongs_to = {'product_id' => 'SampleAdapter'}.to_json
      Source.should_receive(:log).once.with(
        "WARNING: Incorrect belongs_to format for SimpleAdapter, belongs_to should be an array."
      )
      Source.update_associations([@s.name,@s1.name, @s2.name])
    end
  end  
end 