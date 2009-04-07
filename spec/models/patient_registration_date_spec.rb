require File.dirname(__FILE__) + '/../spec_helper'

describe PatientRegistrationDate do

  # If this fails then you need to migrate the views into your test database
  # mysql -u root openmrs_test < db/migrate/patient_registration_dates.sql
  it "should have the view" do
    PatientRegistrationDate.find(:all).should_not be_empty
  end

end
