steps_for(:login) do

  Given "no current user" do     
    @username = nil    
  end

  Given "a username '$username'" do |username|
    @username = username
  end

  Given "a password '$password'" do |password|
    @password = password
  end

  Given "a location '$location'" do |location|
    @location = location
  end

  Given "there is no user with this username" do
    User.find_by_login(@username).should be_nil
  end

  When "the user accesses a page" do
    get "/"
  end

  When "the user logs in with username and password" do
    login_user(@username, @password, @location)
  end

  Then "the login form should be shown again" do
    response.should render_template("user/login")
  end

  Then "should redirect to '$path'" do |path|
    response.should redirect_to(path)
  end
  
  Then "should show message '$message'" do |message|
    response.should have_text(/#{message}/)  
  end

end