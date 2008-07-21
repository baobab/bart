steps_for(:lab_data_migration) do
  
  Given "a logged in user" do
    login_user "mikmck","mike","701"
  end

  Given "a task" do 
    select_task("HIV Reception")
  end
  
  When "the user clicks on finish" do
    post "/patient/menu"
  end

  When "the user clicks on administration" do
    get "/patient/admin_menu"
  end
  
  Then "should redirect to '$path'" do |path| 
    response.should redirect_to(path)
  end

  When "the user clicks on Synchronize" do
    get "/patient/synchronize_data"
  end
  
  When "the user clicks on Sync Lab data" do
    get "/"
  end
  
end
