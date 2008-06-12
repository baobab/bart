class SearchController < ApplicationController
  def multiple
    #URL submitted must use field1, field2, field3...as table column names
    #and model_name1, model_name2, model_name3...etc as table names
    #and search condition as searchkey field
    #example of URL: 
    #http://localhost:3000/search/multiple/?model_name1=PatientName&field1=given_name&model_name2=PatientIdentifier&field2=other_name&searchkey=a 
    
    init_size = 100  #number of rows to retrieve from each table
    final_size = 10  #number of rows to display from final result
    result_string = Array.new 
    result_str = ""

    searchParamIndex = 1
    str_key = searchParamIndex.to_s

    while(!(x=params["field"+str_key]).nil?)
       #compose query and store in an array
       model = params["model_name"+str_key].constantize
       result_string[searchParamIndex] = "select #{x} as col_name, count(#{x}) as freq from #{model.table_name} where #{x} like '%#{params["searchkey"]}%' group by col_name limit #{init_size}" 

       searchParamIndex += 1
       str_key = searchParamIndex.to_s
    end

    #put final query together *note result_string array starts at 1
    query_str = '('+result_string[index=1]+')' if(!result_string[index=1].nil?)

    while(!result_string[(index += 1)].nil?)
       #compose the rest of the union query
       query_str= query_str+' union ('+result_string[index]+')'
    end

    #putting everything together
    sql_stmt = query_str+" order by freq desc limit #{final_size}"

# this is a prepared sql example
#   sql_stmt = '(select given_name as col_name, count(given_name) as freq from patient_name group by col_name) union (select identifier as col_name , count(identifier) as freq from name_tmp group by col_name) order by freq desc limit 10'

    @results = model.find_by_sql sql_stmt

    result_str += '<ul>'
    @results.each { |result| 
      result_str += '<li>' + result.instance_variable_get(:@attributes)["col_name"]  
    }
    result_str += '</ul>'
    render :text => result_str
  end

  def patient_identifier
    result_string = ""
    field_name = "identifier"
    search_string = params[:value]
    patient_identifier_type_id = PatientIdentifierType.find_by_name(params[:type]).id
    model = PatientIdentifier
    primary_key= model.primary_key

# this one matches based on most common match in the database
    @results = model.find_by_sql(["SELECT DISTINCT #{field_name} AS field_name, #{primary_key} AS id FROM #{model.table_name} WHERE identifier_type = #{patient_identifier_type_id} AND #{field_name} LIKE ? GROUP BY #{field_name} ORDER BY COUNT(#{field_name}) DESC, field_name ASC LIMIT 10", "%#{search_string}%"])

    respond_to do |format|
      format.html { render :partial => "search" }
      format.js   { render :action => "search.rjs" }
    end
  end
  
  def method_missing(model_name)
    result_string = ""
    field_name = params[:field]
    search_string = params[:value]
    model = model_name.to_s.constantize
    primary_key= model.primary_key

    if search_string.nil? or search_string == ""
# Show most common matches
      @results = model.find_by_sql(["SELECT DISTINCT #{field_name} AS field_name, #{primary_key} AS id FROM #{model.table_name} WHERE #{field_name} LIKE ? GROUP BY #{field_name} ORDER BY COUNT(#{field_name}) DESC, field_name ASC LIMIT 10", "%#{search_string}%"])
    else
# Give preference to matches that start at beginning of word
      @results = model.find_by_sql(["SELECT DISTINCT #{field_name} AS field_name, #{primary_key} AS id FROM #{model.table_name} WHERE #{field_name} LIKE ? GROUP BY #{field_name} ORDER BY INSTR(#{field_name},\"#{search_string}\") ASC, COUNT(#{field_name}) DESC, field_name ASC LIMIT 10", "%#{search_string}%"])
    end

    respond_to do |format|
      format.html { render :partial => "search" }
      format.js   { render :action => "search.rjs" }
    end
  end


  def identifier
    result = "" 
    identifier_type_id = PatientIdentifierType.find_by_name(params[:type]).patient_identifier_type_id 
    PatientIdentifier.find(:all, :conditions => ["identifier_type = ? AND identifier LIKE ?",identifier_type_id,"%#{params[:text]}%"],:order => "COUNT(identifier) DESC, identifier ASC").collect{|patient_identifier| patient_identifier.identifier}.uniq.each{|identifier|
       result += "<li>" + identifier + "</li>"
    }
    render(:text => result)
  end
  
  def health_center_locations
    @results = Location.health_centers(params[:value]).collect{|location| "<li>#{location.name}</li>"}
    render :text => @results.join("\n")
  end

  def location
    search_string = params[:value]
    @results = Location.get_list.grep(/#{search_string}/i).sort_by{|location|
      location.index(/#{search_string}/) || 100 # if the search string isn't found use value 100
    }[0..15]
    render :text => @results.collect{|location|"<li>#{location}</li>"}.join("\n")
  end

  def ta
    search_string = params[:value]
    @results = Location.get_list.grep(/#{search_string}/i).delete_if{|location|
      location.match(/Area/)
    }.compact.sort_by{|location|
      location.index(/#{search_string}/) || 100 # if the search string isn't found use value 100
    }[0..15]
    render :text => @results.collect{|location|"<li>#{location}</li>"}.join("\n")
  end

  def occupation
occupations = <<EOF
Housewife
Farmer
Soldier/Police
Business
Teacher
Student
Health care worker
Preschool child
Driver
Craftsman
Prisoner
Mechanic
Security Guard
Office
Domestic worker
Not working
Other
Unknown
EOF
    search_string = params[:value]
    @results = occupations.split("\n").collect{|occupation| "<li>#{occupation}</li>" if occupation =~ /#{search_string}/i}.compact
    render :text => @results.join("\n")
  end

end
