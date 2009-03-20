require File.dirname(__FILE__) + '/../spec_helper'

describe FieldAnswer do
  sample({
    :field_id => 1,
    :answer_id => 1,
    :creator => 1,
    :date_created => Time.now,
  })

  it "should be valid" do
    field_answer = create_sample(FieldAnswer)
    field_answer.should be_valid
  end
  
end
