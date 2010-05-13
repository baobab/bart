
def migrate_patients
  table = YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['migration']
  TableMain.establish_connection(table)
  TableHivRelatedIllness.establish_connection(table)
  TableList.establish_connection(table)

  TableMain.create_patients
end
User.current_user = User.find(1)
migrate_patients





