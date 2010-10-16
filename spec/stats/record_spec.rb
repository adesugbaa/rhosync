require 'rhosync'
FOO_RECORD_RESOLUTION = 2
FOO_RECORD_SIZE = 8

include Rhosync
include Rhosync::Stats

describe "Record" do
  
  before(:each) do
    @now = 9
    Store.db.flushdb
  end
  
  it "should add metric to the record and trim record size" do
    Time.stub!(:now).and_return { @now += 1; @now }
    10.times { Record.add('foo') }
    Store.db.zrange('stat:foo', 0, -1).should == ["2:13", "2:15", "2:17", "2:19"]
  end
  
  it "should add single record" do
    Time.stub!(:now).and_return { @now += 1; @now }
    Record.add('foo')
    Store.db.zrange('stat:foo', 0, -1).should == ["1:10"]
  end
  
  it "should return type of metric" do
    Record.add('foo')
    Record.rtype('foo').should == 'zset'
  end
  
  it "should set string metric" do
    Record.set_value('foo', 'bar')
    Store.db.get('stat:foo').should == 'bar'
  end
  
  it "should get string metric" do
    Store.db.set('stat:foo', 'bar')
    Record.get_value('foo').should == 'bar'
  end
  
  it "should get keys" do
    Record.add('foo')
    Record.add('bar')
    Record.keys.sort.should == ['bar','foo']
  end
  
  it "should add absolute metric value" do
    Time.stub!(:now).and_return { @now += 1; @now }
    time = 0
    4.times do 
      Record.add('foo',time) do |current,value|
        Record.save_average(current, value)
      end
      time += 1
    end
    Store.db.zrange('stat:foo', 0, -1).should == ["2.0,1.0:11", "2.0,5.0:13"]
  end
  
  it "should update metric" do
    Rhosync.stats = true
    Time.stub!(:now).and_return { @now += 1; @now }
    4.times do
      Record.update('foo') do
        # something interesting
      end
    end
    Store.db.zrange('stat:foo', 0, -1).should == ["1,1.0:15", "1,1.0:18", "1,1.0:21"]
  end
  
  it "should get range of metric values" do
    Time.stub!(:now).and_return { @now += 1; @now }
    10.times { Record.add('foo') }
    Record.range('foo', 0, 1).should == ["2:13", "2:15"]
  end
  
  it "should reset metric" do
    Time.stub!(:now).and_return { @now += 1; @now }
    10.times { Record.add('foo') }
    Store.db.zrange('stat:foo', 0, -1).should == ["2:13", "2:15", "2:17", "2:19"]
    Record.reset('foo')
    Store.db.zrange('stat:foo', 0, -1).should == []
  end
  
  it "should reset all metrics" do
    Record.add('foo')
    Record.add('bar')
    Record.reset_all
    Store.db.keys('stat:*').should == []
  end
end