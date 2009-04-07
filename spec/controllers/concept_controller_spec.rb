require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ConceptController do

  before do
    login_current_user
    session[:patient_id] = patient(:andreas).id
    session[:encounter_datetime] = Time.now()
  end

end


