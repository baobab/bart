module ConceptSetHelper
  include AjaxScaffold::Helper
  
  def num_columns
    scaffold_columns.length + 1 
  end
  
  def scaffold_columns
    ConceptSet.scaffold_columns
  end

end
