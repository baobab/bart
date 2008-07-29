steps_for(:lab_data_migration) do
  
  Given "a logged in user" do
    @user_password = "mikmck"
    @user_name = "mike"
    @location = "701"
  end

  When "the user clicks Done" do
    login_user @user_password,@user_name,@location
  end
  
  Given "a task" do 
    @task = "HIV Reception"
  end
  
  Given "a list of choices on the patient menu" do 
    @choice = "/patent/admin_menu"
  end
  
  When "the user clicks Finish" do
    select_task(@task)
  end
  
  When "the user clicks Administration" do
    get @choice
  end
  
  Then "should redirect to '$path'" do |path| 
    response.should redirect_to(path)
  end

  When "the user clicks Synchronize" do
    get "/"
  end
  
  When "the user clicks Sync Lab data" do
    get "/"
  end
  
end
