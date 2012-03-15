require File.dirname(__FILE__) + '/../test_helper'

class ReportTest < Test::Unit::TestCase

  def setup
  end

  def test_should_return_date_range_for_quarter
    assert_equal ['2008-01-01'.to_date, '2008-03-31'.to_date], Report.cohort_date_range('Q1 2008')
  end

  def test_should_return_date_range_for_cumulative
    date_range = Report.cohort_date_range('Cumulative')
    assert_equal 2, date_range.length
  end

  def test_should_handle_unknown_quarter_specification
    date_range = Report.cohort_date_range('xxxx')
    assert_equal [nil, nil], date_range
  end

end
 
