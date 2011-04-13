steps_for(:lab_data_migration) do
  
  Given "a logged in user" do
    @user_password = "mikmck"
    @user_name = "mike"
    @location = "7001"
  end

  Given "a task" do 
    @task = "HIV Reception", "Height/Weight", "ART Visit", "Give drugs"
  end
  
  Given "a list of choices on the patient menu" do 
    @choice = "/patent/admin_menu"
  end
  
  When "the user clicks Finish" do
    select_task(@task)
  end
  
  When "the user clicks Synchronize" do
    get "/"
  end
  
  When "the user clicks Sync Lab data" do
    get "/"
  end
  
  When "the user clicks Administration" do
    post "/patient/admin_menu"
  end
  
  When "the user clicks Done" do
    login_user @user_password,@user_name,@location
  end
  
  Then "should redirect to '$path'" do |path| 
    response.should redirect_to(path)
  end

end
