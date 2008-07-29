steps_for(:select_patient) do

  Given "no current patient is selected" do
    login_user('mikmck', 'mike', '7001')
    #session[:patient_id] = nil
    @patient_id = nil
  end

  When "the user scans '$wrong_barcode'" do |barcode|
    get "/patient/set_patient/#{barcode}"
  end
  
  Then "should redirect to '$path'" do |path|
    response.should redirect_to(path)
  end

  Then "should display error '$error'"

end
