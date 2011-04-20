class SampleAdapter < SourceAdapter
  def initialize(source)
    super(source)
  end
 
  def login
    raise SourceAdapterLoginException.new('Error logging in') if _is_empty?(current_user.login)
    true
  end
 
  def query(params=nil)
    _read('query',params)
  end
  
  def search(params=nil)
    _read('search',params)
  end
 
  def sync
    super
  end
 
  def create(name_value_list,blob=nil)
    Store.put_data('test_create_storage',{name_value_list['_id']=>name_value_list},true)
    raise SourceAdapterException.new("ID provided in name_value_list") if name_value_list['id']
    _raise_exception(name_value_list) 
    'backend_id' if name_value_list and name_value_list['link']
  end
 
  def update(name_value_list)
    raise SourceAdapterException.new("No id provided in name_value_list") unless name_value_list['id']
    Store.put_data('test_update_storage',{name_value_list['id']=>name_value_list},true)
    _raise_exception(name_value_list) 
  end
 
  def delete(name_value_list)
    raise SourceAdapterException.new("No id provided in name_value_list") unless name_value_list['id']
    raise SourceAdapterServerErrorException.new("Error delete record") if name_value_list['id'] == ERROR
    Store.put_data('test_delete_storage',{name_value_list['id']=>name_value_list},true)
  end
 
  def logoff
    @result = Store.get_data('test_db_storage')
    raise SourceAdapterLogoffException.new(@result[ERROR]['an_attribute']) if @result[ERROR] and 
      @result[ERROR]['name'] == 'logoff error'
  end
  
  private
  def _is_empty?(str)
    str.length <= 0
  end
  
  def _raise_exception(name_value_list)
    if name_value_list and name_value_list['name'] == 'wrongname' or name_value_list['id'] == 'error'
      raise SourceAdapterServerErrorException.new(name_value_list['an_attribute']) 
    end
  end
  
  def _read(operation,params)
    @result = Store.get_data('test_db_storage')
    if params and params['stash_result']
      stash_result
      # @result is nil at this point; if @result is empty then md will be cleared
    else   
      raise SourceAdapterServerErrorException.new(@result[ERROR]['an_attribute']) if @result[ERROR] and 
        @result[ERROR]['name'] == "#{operation} error"
      @result.reject! {|key,value| value['name'] != params['name']} if params
    end  
    @result
  end
end