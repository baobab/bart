require File.dirname(__FILE__) + '/../test_helper'

class MastercardPdfTest < Test::Unit::TestCase

  def test_should_print_mastercard_pdf
    patient = create_patient
    mastercard_pdf = MastercardPdf.new
    mastercard_pdf.patient = patient
    mastercard_pdf.display(sample_data)
    #assert_pdf_output mastercard_pdf, 1, 0, 0, 'NEW PATIENT MASTER RECORD FOR ARV [front]:'
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
  
  def create_patient(options={})
  end
end
