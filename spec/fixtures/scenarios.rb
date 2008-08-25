  scenario :patient_prescriptions do
    %w( Tom Chris Kevin ).each_with_index do |pp, index|
      PatientPrescription.create(:encounter => pp)
    end
  end
