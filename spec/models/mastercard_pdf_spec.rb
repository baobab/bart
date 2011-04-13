require File.dirname(__FILE__) + '/../spec_helper'

describe MastercardPdf do
  fixtures :patient

  it "should be valid" do
    visit = MastercardPdf.new()
    expected = <<EOF 
680.31 85.04 0.99 -28.35 re f
682.30 85.04 0.99 -28.35 re f
685.28 85.04 0.99 -28.35 re f
688.25 85.04 0.99 -28.35 re f
689.24 85.04 0.99 -28.35 re f
691.23 85.04 0.99 -28.35 re f
692.22 85.04 0.99 -28.35 re f
693.21 85.04 0.99 -28.35 re f
694.20 85.04 0.99 -28.35 re f
696.19 85.04 0.99 -28.35 re f
699.17 85.04 0.99 -28.35 re f
700.16 85.04 0.99 -28.35 re f
701.15 85.04 0.99 -28.35 re f
703.13 85.04 0.99 -28.35 re f
705.12 85.04 0.99 -28.35 re f
706.11 85.04 0.99 -28.35 re f
710.08 85.04 0.99 -28.35 re f
715.04 85.04 0.99 -28.35 re f
717.02 85.04 0.99 -28.35 re f
720.00 85.04 0.99 -28.35 re f
723.97 85.04 0.99 -28.35 re f
725.95 85.04 0.99 -28.35 re f
727.94 85.04 0.99 -28.35 re f
729.92 85.04 0.99 -28.35 re f
732.90 85.04 0.99 -28.35 re f
736.87 85.04 0.99 -28.35 re f
737.86 85.04 0.99 -28.35 re f
738.85 85.04 0.99 -28.35 re f
740.83 85.04 0.99 -28.35 re f
743.81 85.04 0.99 -28.35 re f
744.80 85.04 0.99 -28.35 re f
745.80 85.04 0.99 -28.35 re f
748.77 85.04 0.99 -28.35 re f
750.76 85.04 0.99 -28.35 re f
751.75 85.04 0.99 -28.35 re f
754.72 85.04 0.99 -28.35 re f
755.72 85.04 0.99 -28.35 re f
757.70 85.04 0.99 -28.35 re f
758.69 85.04 0.99 -28.35 re f
760.68 85.04 0.99 -28.35 re f
761.67 85.04 0.99 -28.35 re f
764.65 85.04 0.99 -28.35 re f
766.63 85.04 0.99 -28.35 re f
771.59 85.04 0.99 -28.35 re f
773.57 85.04 0.99 -28.35 re f
BT 680.31 45.70 Td (1234567890126) Tj ET
EOF
    visit.Footer.should == expected
  end

  it "should display data" do 
    patient = patient(:andreas)
    mastercard_pdf = MastercardPdf.new
    mastercard_pdf.patient = patient
    mastercard_pdf.display(sample_data).should == 3882 
  end

private
  def sample_data(options={})
    { :arv_number => "XYZ-123456",    
      :name => "Njero Mckay", 
      :age => 103,
      :sex => "M",
      :initial_weight => 64.9,
      :initial_height => 216.2,
      :transfer_in => false,
      :address => "Area 43, 223 09953440",    
      :agrees_to_follow_up => true,
      :guardian_and_relation => "Happy Person, neighbor",
      :date_and_place_positive_hiv_test => "22/04/06, Kasungu",
      :arv_start_date => Date.new(2006, 3, 17),
      :stage => "III",
      :ptb => true,
      :eptb => true,
      :ks => true,
      :pmtct => true,
      :date_first_line_alternative => Date.new(2006, 4, 17),
      :date_second_line => Date.new(2006, 5, 17),
      :visits => [
        {:visit_date => Date.new(2006, 5, 17),
         :weight => 64.9,
         :height => 173,
         :outcome_status => 'A',
         :start_sub_switch => 'Start',
         :is_ambulatory => true,
         :is_work_school => true,
         :side_effects => ['SK'],
         :total_number_of_pills => 10,
         :number_pills_given => 30,
         :arv_receipient => 'G',
         :cpt => true,
         :other => 'ITN'
        },
        {:visit_date => Date.new(2006, 6, 17),
         :weight => 64.9,
         :height => 173,
         :outcome_status => 'A',
         :start_sub_switch => 'Start',
         :is_ambulatory => true,
         :is_work_school => true,
         :side_effects => ['SK'],
         :total_number_of_pills => 10,
         :number_pills_given => 30,
         :arv_receipient => 'G',
         :cpt => true,
         :other => 'ITN'
        }
      ]
    }.reverse_merge(options)  
  end

end
