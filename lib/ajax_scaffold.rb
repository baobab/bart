module AjaxScaffold # :nodoc:
  class ScaffoldColumn
    attr_reader :name, :eval, :sort_sql, :label, :class_name, :sanitize

    # Only options[:name] is required. It will infer the eval and sort values
    # based on the given class.
    def initialize(klass, options)
      @name = options[:name]
      @eval = options[:eval].nil? ? "#{Inflector.underscore(klass.to_s)}.#{@name}" : options[:eval]
      @label = options[:label].nil? ? Inflector.titleize(@name) : options[:label]
      @sortable = options[:sortable].nil? ? true : options[:sortable]
      @sort_sql = options[:sort_sql].nil? ? "#{klass.table_name}.#{@name}" : options[:sort_sql] unless !@sortable
      @class_name = options[:class_name].nil? ? "" : options[:class_name]
      @sanitize = options[:sanitize].nil? ? true : options[:sanitize]
    end

    def sanitize?
      @sanitize
    end

    def sortable?
      @sortable
    end

  end

  module Common
    def current_sort(params)
      session[params[:scaffold_id]][:sort]
    end

    def current_sort_direction(params)
      session[params[:scaffold_id]][:sort_direction]
    end
  end

  module Controller
    include AjaxScaffold::Common

    def clear_flashes
      if request.xhr?
        flash.keys.each do |flash_key|
          flash[flash_key] = nil
        end
      end
    end

    def default_per_page
      25
    end

    def store_or_get_from_session(id_key, value_key)
      session[id_key][value_key] = params[value_key] if !params[value_key].nil?
      params[value_key] ||= session[id_key][value_key]
    end

    def update_params(options)
      @scaffold_id = params[:scaffold_id] ||= options[:default_scaffold_id]
      session[@scaffold_id] ||= {:sort => options[:default_sort], :sort_direction => options[:default_sort_direction], :page => 1}

      store_or_get_from_session(@scaffold_id, :sort)
      store_or_get_from_session(@scaffold_id, :sort_direction)
      store_or_get_from_session(@scaffold_id, :page)
    end

  end

  module Helper
    include AjaxScaffold::Common

    def format_column(column_value, sanitize = true)
      if column_empty?(column_value)
        empty_column_text
      elsif column_value.instance_of? Time
        format_time(column_value)
      elsif column_value.instance_of? Date
        format_date(column_value)
      else
        sanitize ? h(column_value.to_s) : column_value.to_s
      end
    end

    def format_time(time)
      time.strftime("%m/%d/%Y %I:%M %p")
    end

    def format_date(date)
      date.strftime("%m/%d/%Y")
    end

    def column_empty?(column_value)
      column_value.nil? || (column_value.empty? rescue false)
    end

    def empty_column_text
      "-"
    end

    # Generates a temporary id for creating a new element
    def generate_temporary_id
      (Time.now.to_f*1000).to_i.to_s
    end

    def pagination_ajax_links(paginator, params)
      pagination_links_each(paginator, {}) do |n|
        link_to_remote n,
           { :url => params.merge(:page => n ),
           :loading => "Element.show('#{loading_indicator_id(params.merge(:action => 'pagination'))}');",
           :update => scaffold_content_id(params) },
           { :href => url_for(params.merge(:page => n )) }
      end
    end

    def column_sort_direction(column_name, params)
      if column_name && column_name == current_sort(params)
        current_sort_direction(params) == "asc" ? "desc" : "asc"
      else
        "asc"
      end
    end

    def column_class(column_name, column_value, sort_column, class_name = nil)
      class_attr = String.new
      class_attr += "empty " if column_empty?(column_value)
      class_attr += "sorted " if (!sort_column.nil? && column_name == sort_column)
      class_attr += "#{class_name} " unless class_name.nil?
      class_attr
    end

    def loading_indicator_tag(options)
      image_tag "indicator.gif", :style => "display:none;", :id => loading_indicator_id(options), :alt => "loading indicator", :class => "loading-indicator"
    end

    # The following are a bunch of helper methods to produce the common scaffold view id's

    def scaffold_content_id(options)
      "#{options[:scaffold_id]}-content"
    end

    def scaffold_column_header_id(options)
      "#{options[:scaffold_id]}-#{options[:column_name]}-column"
    end

    def scaffold_tbody_id(options)
      "#{options[:scaffold_id]}-tbody"
    end

    def scaffold_messages_id(options)
      "#{options[:scaffold_id]}-messages"
    end

    def empty_message_id(options)
      "#{options[:scaffold_id]}-empty-message"
    end

    def element_row_id(options)
      "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-row"
    end

    def element_cell_id(options)
      "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-cell"
    end

    def element_form_id(options)
      "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-form"
    end

    def loading_indicator_id(options)
      if options[:id].nil?
        "#{options[:scaffold_id]}-#{options[:action]}-loading-indicator"
      else
        "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-loading-indicator"
      end
    end

    def element_messages_id(options)
      "#{options[:scaffold_id]}-#{options[:action]}-#{options[:id]}-messages"
    end
  end

  module Model
    module ClassMethods

    def build_scaffold_columns
      scaffold_columns = Array.new
      content_columns.each do |column|
        scaffold_columns << ScaffoldColumn.new(self, { :name => column.name })
      end
      scaffold_columns
    end

    def build_scaffold_columns_hash
      scaffold_columns_hash = Hash.new
      scaffold_columns.each do |scaffold_column|
        scaffold_columns_hash[scaffold_column.name] = scaffold_column
      end
        scaffold_columns_hash
      end
    end
  end
end

class ActiveRecord::Base
  extend AjaxScaffold::Model::ClassMethods

  @scaffold_columns = nil
  def self.scaffold_columns
    @scaffold_columns ||= build_scaffold_columns
  end

  @scaffold_columns_hash = nil
  def self.scaffold_columns_hash
    @scaffold_columns_hash ||= build_scaffold_columns_hash
  end
end
