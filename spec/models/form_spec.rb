require File.dirname(__FILE__) + '/../spec_helper'

describe Form do

  sample({
    :form_id => 1,
    :name => '',
    :version => '',
    :build => 1,
    :published => 1,
    :description => '',
    :encounter_type => 1,
    :schema_namespace => '',
    :template => '',
    :infopath_solution_version => '',
    :uri => '',
    :xslt => '',
    :creator => 1,
    :date_created => Time.now,
    :changed_by => 1,
    :date_changed => Time.now,
    :retired => false,
    :retired_by => 1,
    :date_retired => Time.now,
    :retired_reason => '',
  })

  it "should be valid" do
    form = create_sample(Form)
    form.should be_valid
  end
  
end
