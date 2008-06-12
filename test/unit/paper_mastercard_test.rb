require File.dirname(__FILE__) + '/../test_helper'

class PaperMastercardTest < Test::Unit::TestCase
  fixtures :mastercards

  @@today = Date.today
  @@sixty_days_ago = Date.today - 60

  def test_can_get_required_data
    paper_mastercard = PaperMastercard.get_required_data("DZA0002")
    assert_equal "DZA0002", paper_mastercard.arv_number
    assert_equal "Lyson", paper_mastercard.first_name
    assert_equal "Chiwalo", paper_mastercard.last_name
    assert_equal 36, paper_mastercard.age
    assert_equal "Male", paper_mastercard.sex
    assert_equal 43.0, paper_mastercard.initial_weight
    assert_equal 155.0, paper_mastercard.initial_height
    assert_equal false, paper_mastercard.transfer_in
    assert_equal "K/minga /K/gwaza", paper_mastercard.address
    assert_equal "Sella Lyson", paper_mastercard.guardian_name
    assert_equal "Dedza", paper_mastercard.hiv_test_place
    assert_equal "Oral candidiasis,Chronic diarrhoea", paper_mastercard.reason_for_starting
    assert_equal nil, paper_mastercard.ptb
    assert_equal nil, paper_mastercard.eptb
    assert_equal nil, paper_mastercard.ks
    assert_equal nil, paper_mastercard.pmtct
    assert_equal "2005-01-05", paper_mastercard.hiv_test_date
    assert_equal "2005-01-25", paper_mastercard.date_of_starting_1st_line
    assert_equal nil, paper_mastercard.date_of_starting_1st_line_alternative
    assert_equal nil, paper_mastercard.date_of_starting_2nd_line
    assert_equal "Dead", paper_mastercard.last_outcome
  end

=begin # TODO
  def test_can_parse_reason_for_starting
    strings = ["Stage 3", "III", "lll", "Stage III", "3"]
    strings.each{|string|
      assert PaperMastercard.parse_reason_for_starting(string) == "Unspecified stage 3"
    } 
    strings = ["Stage 2", "II", "ll", "Stage II", "2"]
    strings.each{|string|
      assert PaperMastercard.parse_reason_for_starting(string) == "Unspecified stage 2"
    } 
    strings = ["CD4 220" ]
    strings.each{|string|
      assert PaperMastercard.parse_reason_for_starting(string) == "CD4 220"
    } 
    strings = ["CD4 <220", "CD4 < 220" ]
    strings.each{|string|

      assert PaperMastercard.parse_reason_for_starting(string) == "CD4 < 220"
    } 
    strings = ["CD4 220%", "CD4 220 %", "CD4 percent 220" ]
    strings.each{|string|
      assert PaperMastercard.parse_reason_for_starting(string) == "CD4% 220"
    } 
  end
=end

private
  def create(options={})
    User.create(user_default_values.merge(options))
  end

end
