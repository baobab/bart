steps_for(:select_patient) do

  Given "no current patient is selected" do
    login_user('mikmck', 'mike', '7001')
    get '/patient/menu', {:no_auto_load_forms => true}
    #session[:patient_id] = nil
    @patient_id = nil
  end

  Given "a patient '$barcode' is selected" do |barcode|
    login_user('mikmck', 'mike', '7001')
    post "/patient/set_patient/#{barcode}"
  end

  Then "should redirect to '$path'" do |path|
    response.should redirect_to(path)
  end

  Then "should display text '$text'" do |text|
    follow_redirect!
    response.should have_text(/#{text}/)
  end

  When "the user scans '$wrong_barcode'" do |barcode|
    post "/patient/set_patient/#{barcode}"
  end
  
end
