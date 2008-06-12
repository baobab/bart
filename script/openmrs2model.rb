#!/usr/bin/ruby -w
#
# Baobab Health Partnership - www.baobabhealth.org
# Written by Mike McKay mike@vdomck.org
#
require "rubygems"
require 'active_support/inflector'

def singularize(string)
  unless(string =~ /ss$/) then
    return Inflector.singularize(string)
  end
  return string
end
        
class Model
  def initialize(name)
    @name = name
    @has_many_relationships = Hash.new
    @belongs_to_relationships = Hash.new
    @primary_keys = Array.new
  end

  def add_primary_key(primary_key)
    @primary_keys.push(primary_key)
  end

  def add_has_many(tablename, foreign_key)
    @has_many_relationships[tablename] = foreign_key
  end

  def add_belongs_to(tablename, foreign_key)
    @belongs_to_relationships[tablename] = foreign_key
  end

  def set_original_sql(original_sql)
    @original_sql = original_sql
  end

  def print_class
    puts class_definition
  end

  def class_name
    return singularize(@name.capitalize.gsub(/_(.)/) {$1.capitalize})
  end
  
  def file_name
    return singularize(@name).downcase;
  end
 
  def commented_out_original_sql
    returnValue = "### Original SQL Definition for #{@name} ###"
    @original_sql.split(/\n/).each{|line|
      returnValue += "# " + line + "\n"
    }
    return returnValue
  end
  
  def class_definition
    returnValue = ""
    returnValue += "require composite_primary_keys\n" if @primary_keys.length > 1
    returnValue += "class #{class_name} < ActiveRecord::Base\n"
    returnValue += "  set_table_name \"#{@name}\"\n"
    @has_many_relationships.each{ |tablename, foreign_key|
      returnValue += "  has_many :#{Inflector.pluralize(tablename)}, :foreign_key => :#{foreign_key}\n"
    }
    @belongs_to_relationships.each{ |tablename, foreign_key |
      returnValue += "  belongs_to :#{singularize(tablename)}, :foreign_key => :#{foreign_key}\n"
    }
    if @primary_keys.length > 1
      returnValue += "  set_primary_keys " + @primary_keys.collect{|key| ":" + key }.join(", ") + "\n"
    else
      returnValue += "#" + @primary_keys.to_s + "\n"
      returnValue += "  set_primary_key \"#{@primary_keys[0]}\"\n" if @primary_keys
    end
    returnValue += "end"
    return returnValue
  end
end

myModels = Hash.new

File.readlines("openmrs_1.1.0-mysql.sql", ";").each { |sqlcommand|
  next if sqlcommand.match(/^\/|^--/)
  sqlcommand.match(/CREATE TABLE `(.*?)` \((.*)\)/m)
  next unless $1
  tableName = $1
  myModels[tableName] = Model.new(tableName) unless myModels[tableName]
  myModels[tableName].set_original_sql($2)
  $2.split(/,\n/).each{|line|
    if line =~ /CONSTRAINT `(.*)` FOREIGN KEY \(`(.*)`\) REFERENCES `(.*)` \(`(.*)`\)/ then
      relationshipName = $1
      foreign_key = $2
      tableReference = $3
      reference_key = $4
      myModels[tableReference] = Model.new(tableReference) unless myModels[tableReference]
      myModels[tableReference].add_has_many(tableName,foreign_key)
      myModels[tableName].add_belongs_to(tableReference, reference_key)
    elsif line =~ /PRIMARY KEY  \((.*)\)/ then
      $1.split(",").collect{|key| key.gsub!(/`/,'')}.each{ |key|
        myModels[tableName].add_primary_key(key) 
      }
    end
  }
}


myModels.each{ |key, model|
#  model.print_class
  file = File.open("output/"+model.file_name+".rb", File::WRONLY|File::TRUNC|File::CREAT)
  file.puts(model.class_definition)
  file.puts("\n\n"+model.commented_out_original_sql)
  file.close
}
