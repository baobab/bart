steps_for(:enter_patient_vitals) do
  
  Given "a logged in user" do 
    login_user "mikmck","mike","7001" 
  end 
  
  Given "a task" do 
    @task = "HIV Reception", "Height/Weight"       
  end
  
  When "the user clicks Finish" do
    select_task(@task)
  end
  
  When "the user clicks Next" do
   get '/form/show/47', {:no_auto_load_forms => true}
  end
  
  When "the user scans '$barcode'" do |barcode|
   post "/patient/set_patient/#{barcode}"
  end 

  When "the user enters the vitals and clicks Finish" do
    form_id = Form.find_by_name('Height/Weight').id
    concept_weight_id = Concept.find_by_name("Weight").id
    concept_height_id = Concept.find_by_name("Height").id
    post '/encounter/create',
         {"form_id"=>"#{form_id}",
          "observation"=>{concept_weight_id=>"60.0",
          concept_height_id=>"166"},
          "encounter_type_id"=>"7"}
  end

  Then "should redirect to '$path'" do |path| 
    response.should redirect_to(path)
  end

end
