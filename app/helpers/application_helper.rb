# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def observation_select(field, options, attributes, type="select")
    attributes_as_text = attributes.collect{|name,value| "#{name}=\"#{value}\""}.join(" ")
    select("observation", "#{type}:#{field.concept.id}", options, {:include_blank => true}).gsub(/<select/, "<select #{attributes_as_text}")
  end

  def select_tag_for_array(name, option_tags = nil, options = {})
    option_tags = "<option>" + option_tags.join("</option><option>") + "</option>"
    attributes_as_text = options.collect{|name,value| "#{name}=\"#{value}\""}.join(" ")
    #select_tag(name, option_tags, options)
    select_tag(name, option_tags, {}).gsub(/<select/, "<select #{attributes_as_text}")
  end

  def date_select_with_attributes(object_name, method, options = {}, attributes = {})
    attributes_as_text = attributes.collect{|name,value| "#{name}=\"#{value}\""}.join(" ") unless attributes.empty?
    date_select(object_name, method, options).gsub(/<select/, "<select #{attributes_as_text}")

  end
  
  def link_to_onmousedown(name, options = {}, html_options = nil, *parameters_for_method_reference)
    html_options = Hash.new if html_options.nil?
    html_options["onMouseDown"]="this.style.backgroundColor='lightblue';document.location=this.href"
    html_options["onClick"]="return false" #if we don't do this we get double clicks
    link = link_to(name, options, html_options, *parameters_for_method_reference)
  end

  def link_to_onmousedown_in_tr_td(name, options = {}, html_options = nil, *parameters_for_method_reference)
    return "<tr><td #{"style='" + html_options[:style] + "'" unless html_options.nil? or html_options[:style].nil?} onMousedown='this.style.backgroundColor = \"lightblue\";document.location = this.firstChild.href;return false;'>" + link_to_onmousedown(name, options, html_options, *parameters_for_method_reference) + "</tr></td>"
  end

  def add_attribute_to_input_field!(form_element, name, value)
    form_element.sub!(/<input/, "<input #{name}=\"#{value}\"")
  end
  def add_attribute_to_select_field!(form_element, name, value)
    form_element.sub!(/<select/, "<select #{name}=\"#{value}\"")
  end
  def add_attribute_to_input_or_select_field!(form_element, name, value)
    add_attribute_to_input_field!(form_element, name,value)
    add_attribute_to_select_field!(form_element, name,value)
  end
  def add_attribute_to_all_options_field!(form_element,name, value)
    form_element.gsub!(/<option(.*?)>/){"<option#{$1} #{name}=\"#{value}\">"}
  end
  def add_attribute_to_option_field!(form_element,option_text_to_match,name, value)
    form_element.gsub!(/<option(.*?)>(#{option_text_to_match})<\/option>/){"<option#{$1} #{name}=\"#{value}\">#{$2}</option>"}
  end
  def quarter_array(start_date, end_date)
    arr = []
    currquarter = (start_date.month.to_f/3).ceil
    curryear = start_date.year
    while (curryear < end_date.year || (curryear == end_date.year && currquarter <= (end_date.month.to_f/3).ceil)) do
      arr << "Q#{currquarter} #{curryear}"
      currquarter += 1
      if (currquarter > 4)
        currquarter = 1
        curryear += 1
      end
    end
		arr << "Cumulative"
    arr.reverse
  end
  
  # Helper functions that allow you to make something a link only if the user 
  # has the privilege necessary to use the link. The action should still be 
  # protected in the corresponding action and controller
  # In the long run, using this for the same privilege over and over is a bit
  # un optimized
  def privileged_link_to(privilege, name, options = {}, html_options = nil, *parameters_for_method_reference)
    User.current_user.has_privilege_by_name(privilege) ? link_to(name, options, html_options, parameters_for_method_reference) : name  
  end
  
  def privileged_link_to_onmousedown(privilege, name, options = {}, html_options = nil, *parameters_for_method_reference)
    User.current_user.has_privilege_by_name(privilege) ? link_to_onmousedown(name, options, html_options, parameters_for_method_reference) : name  
  end
end
