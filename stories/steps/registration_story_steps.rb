steps_for(:registration) do
  
  Given "a logged in user"  do
     login_user('mikmck', 'mike', '7001')
     get '/patient/menu', {:no_auto_load_forms => true}
  end

  When "the user clicks Register patient" do
   get "patient/new", {:no_auto_load_forms => true}
  end 
    
  Then "should redirect to '$path'" do |path| 
    response.should redirect_to(path)
  end

end
