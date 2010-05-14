require 'resque'
require 'rhosync/jobs/bulk_data_job'

module Rhosync
  class BulkData < Model
    field :name, :string
    field :state, :string
    field :app_id, :string
    field :user_id, :string
    field :refresh_time, :integer
    field :dbfile,:string
    set   :sources, :string
    validates_presence_of :app_id, :user_id, :sources
    
    def completed?
      if state.to_sym == :completed and 
        dbfile and File.exist?(dbfile)
        return true
      end
      false
    end
    
    def delete
      sources.members.each do |source|
        s = Source.load(source,{:app_id => app_id, :user_id => user_id})
        Store.flash_data(s.docname(:md_copy)) if s
      end
      super
    end
    
    def process_sources
      sources.members.each do |source|
        s = Source.load(source,{:app_id => app_id, :user_id => user_id})
        if s
          SourceSync.new(s).process_query(nil)
          s.clone(:md,:md_copy) unless s.sync_type.to_sym == :bulk_sync_only
        end
      end
    end
    
    def url
      File.join('/data',dbfile[Rhosync.data_directory.length..-1])
    end
    
    class << self
      def create(fields={})
        fields[:id] = fields[:name]
        fields[:state] ||= :inprogress
        fields[:sources] ||= []
        super(fields)
      end
      
      def enqueue(params={})
        Resque.enqueue(BulkDataJob,params)
      end
      
      def get_name(partition,client)
        if partition == :user
          File.join(client.app_id,client.user_id,client.user_id)
        else
          File.join(client.app_id,client.app_id)
        end
      end
      
      def schema_file
        File.join(File.dirname(__FILE__),'syncdb.schema')
      end
      
      def index_file
        File.join(File.dirname(__FILE__),'syncdb.index.schema')
      end
    end
  end
end

