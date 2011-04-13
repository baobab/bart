steps_for(:select_patient) do

  Given "a patient '$barcode' is selected on reception" do |barcode|
    login_user('mikmck', 'mike', '7001')
    post '/user/change_activities', {'user' => {'activities' => ["HIV Reception", "Height/Weight", "ART Visit", "Give drugs"]}}
    post "/patient/set_patient/#{barcode}"
    post "/form/show/55"
    response.should have_text(/Guardian present/)
    Patient.find_by_national_id(barcode).first.encounters.find_by_date(Date.today).length.should == 0
  end

  When "user enters Guardian present '$guardian_presence' and Patient present '$patient_presence'" do |guardian_present,patient_present|
    
    form_id = Form.find_by_name('HIV Reception').id
    guardian_present_answer_id = Concept.find_by_name(guardian_present).id
    patient_present_answer_id = Concept.find_by_name(patient_present).id
    post '/encounter/create', 
         {"form_id"=>"#{form_id}",
          "observation"=>{"select:398"=>guardian_present_answer_id,
          "select:399"=>patient_present_answer_id},
          "encounter_type_id"=>"6"}
  end

  Then "should redirect to '$path'" do |path|
    response.should redirect_to(path)
  end

  Then "should display texts '$text1' and '$text2'" do |text1,text2|
    get '/patient/menu?no_auto_load_forms=true'
    follow_redirect! if response.code == 302
    response.should have_text(/#{text1}*#{text2}/)
  end
  
  When "user goes to redirected page" do
    follow_redirect! if response.code == 302
  end
  
  Then "observations for last encounter for patient '$patient_barcode' should be '$observation_strings'" do |patient_barcode,obs_string|
    Patient.find_by_national_id(patient_barcode).first.encounters.find_by_date(Date.today).length.should == 1
    Patient.find_by_national_id(patient_barcode).first.encounters.last.observations.map(&:to_s).join(',').should == obs_string
  end

end
