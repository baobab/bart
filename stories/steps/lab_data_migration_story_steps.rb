steps_for(:lab_data_migration) do
  
  Given "a username '$username'" do |username|
    @username = username
  end

  Given "a password '$password'" do |password|
    @password = password
  end
  
  Given "a location '$location'" do |location|
    @location = location
  end

  When "the user logs in with username and password" do
    login_user(@username, @password, @location)
  end

  Then "should redirect to '$path'" do |path|
    response.should redirect_to(path)
  end

  Given "a logged in user" do
    login_user "mikmck","mike","701"
  end

  Given "a task '$task'" do |task|
    @task = task
  end

  When "the user submits the task" do
    post "/user/change_activities", :user => { :activities => @task }
  end

  Then "should redirect to '$path'" do |path|
    response.should redirect_to(path)
  end

end
