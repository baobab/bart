steps_for(:print_national_id) do
  
  Given "a selected patient"  do
     login_user('mikmck', 'mike', '7001')
     get '/patient/menu', {:no_auto_load_forms => true}
  end

  Given "a selected patient main menu"  do
     get '/patient/menu', {:no_auto_load_forms => true}
  end

  When "a user clicks on mastercard" do
    post "/patient/mastercard/#{@patient_id}"
  end

  When "the user scans '$wrong_barcode'" do |barcode|
   post "/patient/set_patient/#{barcode}"
   @patient_id = session[:patient_id]
  end 
    
  When "the user clicks Cancel" do
   get '/patient/menu', {:no_auto_load_forms => true}
  end
  
  Then "should redirect to '$path'" do |path| 
    response.should redirect_to(path)
  end

end
