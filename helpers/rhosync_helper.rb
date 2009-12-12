helpers do
  def login_required
    current_user.nil?
  end
  
  def login
    user = User.authenticate(params[:login], params[:password])
    if user
      session[:login] = user.login
      true
    else
      false
    end
  end
  
  def logout
    session[:login] = nil
  end
  
  def current_user
    if User.is_exist?(session[:login])
      User.with_key(session[:login])
    end
  end
  
  def current_app
    App.with_key(params[:app_name]) if params[:app_name]
  end
  
  def current_source
    Source.with_key(params[:source_name]) if params[:source_name]
  end
  
  def current_client
    Client.with_key(params[:client_id]) if params[:client_id]
  end
  
  def upload_file
    
    "appdir: #{appdir.inspect}, filename: #{uploaded_file.inspect}"
  end
end