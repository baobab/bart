module GlobalPropertyHelper
  include AjaxScaffold::Helper
  
  def num_columns
    scaffold_columns.length + 1 
  end
  
  def scaffold_columns
    GlobalProperty.scaffold_columns
  end

end
