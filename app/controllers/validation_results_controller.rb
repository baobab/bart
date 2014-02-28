
class ValidationResultsController < ActionController::Base

  def initialize

		@@first_registration_date = FlatCohortTable.find(
		  :first,
		  :order => 'earliest_start_date ASC'
		).earliest_start_date.to_date rescue nil
	end

  def list
    start_date = params[:start_date]
    end_date = params[:end_date]
    results = ValidationResult.find(
      :all, #:include => :validation_rules,
      :select => 'rule_id, failures, date_checked',
      :conditions => ['date_checked >= ? AND date_checked <= ?',
                      start_date.to_date, end_date.to_date])
    
    resp = results.map { |r| {:rule_id => r.rule_id,:rule_desc => r.validation_rule.desc ,
                              :date_checked => r.date_checked.strftime("%Y-%m-%d"),
                              :failures => r.failures}
                       }
    respond_to do |format|
      format.json { render :json => resp }
      format.html { render :text => resp.to_yaml }
    end
  end
  
  
  def summary
    start_date = params[:start_date]
    end_date = params[:end_date]
    
    total_rules = ValidationRule.count(:all, :conditions => ['type_id = ?', 2])
    results = ValidationResult.find(
      :all, #:include => :validation_rules,
      :select => "date_checked, COUNT(failures) AS passed, #{total_rules} AS total",
      :conditions => ['date_checked >= ? AND date_checked <= ? AND failures = 0',
                      start_date.to_date, end_date.to_date],                
      :group => 'date_checked' 
     )

    resp = results.map { |r| {:date_checked => r.date_checked.strftime("%Y-%m-%d"),
                               :passed => r.passed,
                               :total => r.total}
                       }
    
    respond_to do |format|
      
      format.json { render :json => resp}

      format.html { render :text => resp.to_yaml }
    end
  end
end
