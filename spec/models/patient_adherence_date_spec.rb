require File.dirname(__FILE__) + '/../spec_helper'

describe PatientAdherenceDate do

  before do
    create_view :patient_dispensations_and_prescriptions
  end

  # If this fails then you need to migrate the views into your test database
  # mysql -u root openmrs_test < db/migrate/patient_start_dates.sql
  it "should have the view" do
    PatientAdherenceDate.find(:all).should_not be_empty
  end

end
