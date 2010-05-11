
def migrate_patients
  table = YAML.load(File.open(File.join(RAILS_ROOT, "config/database.yml"), "r"))['migration']
  TableMain.establish_connection(table)

  TableMain.create_patients
end

migrate_patients





