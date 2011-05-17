module Rhosync
  class Source < Model
#    field :source_id,:integer
#    field :name,:string
#    field :url,:string
#    field :login,:string
#    field :password,:string
#    field :priority,:integer
#    field :callback_url,:string
#    field :poll_interval,:integer
#    field :partition_type,:string
#    field :sync_type,:string
#    field :belongs_to,:string
#    field :has_many,:string
#    field :queue,:string
#    field :query_queue,:string
#    field :cud_queue,:string

#    attr_accessor :name
#    attr_accessor :url
#    attr_accessor :login, :password
#    attr_accessor :callback_url
#    attr_accessor :partition_type
#    attr_accessor :sync_type
#    attr_accessor :queue, :query_queue, :cud_queue
#    attr_accessor :pass_through
    #    attr_accessor :belongs_to
    #    def belongs_to
    #      return @@source_data[@name.to_sym][:belongs_to] if @name    
    #      @belongs_to
    #    end
    #    def belongs_to=(assoc)
    #      @@source_data[@name.to_sym][:belongs_to] = assoc if @name    
    #      @belongs_to = assoc
    #    end
    #    def source_id
    #      return @@source_data[@name.to_sym][:source_id] if @name   
    #      @source_id
    #    end
    #    def source_id=(value)
    #      @@source_data[@name.to_sym][:source_id] = value.to_i if @name   
    #      @source_id = value.to_i
    #    end
        
    #    def priority
    #      return @@source_data[@name.to_sym][:priority] if @name && @@source_data[@name.to_sym]
    #      @priority
    #    end    
    #    def priority=(value)
    #      @@source_data[@name.to_sym][:priority] = value.to_i if @name && @@source_data[@name.to_sym]   
    #      @priority = value.to_i
    #    end
    
    #    def poll_interval
    #      return @@source_data[@name.to_sym][:poll_interval] if @name && @@source_data[@name.to_sym]   
    #      @poll_interval
    #    end
    #    def poll_interval=(value)
    #      @@source_data[@name.to_sym][:poll_interval] = value.to_i if @name && @@source_data[@name.to_sym]  
    #      @poll_interval = value.to_i
    #    end

    field :foo_id,:string # FIXME: dummy field
    @@source_data = {}
    
    [:name, :url, :login, :password, :callback_url, :partition_type, :sync_type, 
      :queue, :query_queue, :cud_queue, :pass_through, :belongs_to].each do |attr|
      define_method("#{attr}=") do |value|
        return @@source_data[id.to_sym][attr.to_sym] = value if @@source_data[id.to_sym] #if @name && @@source_data[@name.to_sym]
        instance_variable_set(:"@#{attr}", value)
      end
      define_method("#{attr}") do
        return @@source_data[id.to_sym][attr.to_sym] if @@source_data[id.to_sym] #if @name && @@source_data[@name.to_sym]
        instance_variable_get(:"@#{attr}")
      end
    end
    
    # attr_accessor :has_many
    def has_many
      return @@source_data[id.to_sym][:has_many] if @@source_data[id.to_sym]   
      @has_many
    end
    def has_many=(attrib)
      @@source_data[id.to_sym][:has_many]  = attrib.nil? ? '' : attrib if @@source_data[id.to_sym]  
      @has_many = attrib
    end

    #    attr_accessor :source_id
    #    attr_accessor :priority
    #    attr_accessor :poll_interval
    [:source_id, :priority, :poll_interval].each do |attr|
       define_method("#{attr}=") do |value|
         return @@source_data[id.to_sym][attr.to_sym] = value.to_i if id && @@source_data[id.to_sym]
         instance_variable_set :"@#{attr}", value.to_i 
       end
      define_method("#{attr}") do
        return @@source_data[id.to_sym][attr.to_sym] if id && @@source_data[id.to_sym]
        instance_variable_get :"@#{attr}"
      end
     end
          
    attr_accessor :app_id, :user_id
    validates_presence_of :name #, :source_id
    
    include Document
    include LockOps
  
    def self.set_defaults(fields)
      fields[:url] ||= ''
      fields[:login] ||= ''
      fields[:password] ||= ''
      fields[:priority] ||= 3
      fields[:partition_type] ||= :user
      fields[:poll_interval] ||= 300
      fields[:sync_type] ||= :incremental
      fields[:belongs_to] = fields[:belongs_to].to_json if fields[:belongs_to]
      fields[:schema] = fields[:schema].to_json if fields[:schema]
    end
        
    def self.create(fields,params)
      fields = fields.with_indifferent_access # so we can access hash keys as symbols
      # validate_attributes(params)
      fields[:id] = fields[:name]
      set_defaults(fields)
#      super(fields,params)
      obj = super(fields,params)  # FIXME:      
      h = {}
      fields.each do |name,value|
        if obj.respond_to?(name)
          h[name.to_sym] = value  
        end
      end
      @@source_data[obj.id.to_sym] = h
      obj      
    end
    
    def self.load(id,params)
      validate_attributes(params)
      #      super(id,params)
      obj = super(id,params)
      if obj
        if @@source_data[obj.id.to_sym]
          @@source_data[obj.id.to_sym].each do |k,v|
            obj.send "#{k.to_s}=".to_sym, v.to_s          
          end
        end  
      end
      obj
    end
    
    def self.update_associations(sources)
      params = {:app_id => APP_NAME,:user_id => '*'}
      sources.each { |source| Source.load(source, params).has_many = nil }
      sources.each do |source|
        s = Source.load(source, params)
        if s.belongs_to
          belongs_to = JSON.parse(s.belongs_to)
          if belongs_to.is_a?(Array)
            belongs_to.each do |entry|
              attrib = entry.keys[0]
              model = entry[attrib]
              owner = Source.load(model, params)
              owner.has_many = owner.has_many.length > 0 ? owner.has_many+',' : ''
              owner.has_many += [source,attrib].join(',')
            end
          else
            log "WARNING: Incorrect belongs_to format for #{source}, belongs_to should be an array."
          end
        end
      end
    end
    
    def blob_attribs
      return '' unless self.schema
      schema = JSON.parse(self.schema)
      blob_attribs = []
      schema['property'].each do |key,value|
        values = value ? value.split(',') : []
        blob_attribs << key if values.include?('blob')
      end
      blob_attribs.sort.join(',')
    end
    
    def update(fields)
      fields = fields.with_indifferent_access # so we can access hash keys as symbols
      self.class.set_defaults(fields)
      obj = super(fields)
      # TODO:
#      if obj
#        if @@source_data[obj.id.to_sym]
#          @@source_data[obj.id.to_sym].each do |k,v|
#            obj.send "#{k.to_s}=".to_sym, v.to_s          
#          end
#        end  
#      end
      obj
    end
    
    def clone(src_doctype,dst_doctype)
      Store.clone(docname(src_doctype),docname(dst_doctype))
    end
    
    # Return the user associated with a source
    def user
      @user ||= User.load(self.user_id)
    end
    
    # Return the app the source belongs to
    def app
      @app ||= App.load(self.app_id)
    end
    
    def schema
      @schema ||= self.get_value(:schema)
    end
    
    def read_state
      id = {:app_id => self.app_id,:user_id => user_by_partition,
        :source_name => self.name}
      @read_state ||= ReadState.load(id)
      @read_state ||= ReadState.create(id)   
    end
    
    def doc_suffix(doctype)
      "#{user_by_partition}:#{self.name}:#{doctype.to_s}"
    end
    
    def delete
      ref_to_data = id.to_sym
      flash_data('*')
      super
      @@source_data[ref_to_data] = nil if ref_to_data
      
    end
    
    def partition
      self.partition_type.to_sym
    end
    
    def partition=(value)
      self.partition_type = value
    end
    
    def user_by_partition
      self.partition.to_sym == :user ? self.user_id : '__shared__'
    end
  
    def check_refresh_time
      self.poll_interval == 0 or 
      (self.poll_interval != -1 and self.read_state.refresh_time <= Time.now.to_i)
    end
        
    def if_need_refresh(client_id=nil,params=nil)
      need_refresh = lock(:md) do |s|
        check = check_refresh_time
        s.read_state.refresh_time = Time.now.to_i + s.poll_interval if check
        check
      end
      yield client_id,params if need_refresh
    end
        
    def is_pass_through?
      self.pass_through and self.pass_through == 'true'
    end
          
    private
    def self.validate_attributes(params)
      raise ArgumentError.new('Missing required attribute user_id') unless params[:user_id]
      raise ArgumentError.new('Missing required attribute app_id') unless params[:app_id]
    end
  end
end