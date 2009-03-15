require 'factory_girl/syntax/sham'

Sham.email      {|n| "somebody#{n}@example.com" }
Sham.username   {|n| "mike#{n}" }
Sham.first_name {|n| "Mike#{n}" }
Sham.last_name  {|n| "McKay#{n}" }
Sham.password   {|n| "rAnDoMsTrInG#{n}" }

Factory.define :drug do |d|
  d.date_created  { Time.now.to_formatted_s(:db) }
  d.name          "Stavudine 6"
  d.route         "PO"
  d.units         "mg"
  d.combination   true
  d.association   :creator, :factory => :user
  d.association   :concept
end

Factory.define :drug_order do |d|
  d.association :order
  d.association :drug_inventory
end

Factory.define :encounter do |e|
  e.encounter_datetime { 1.week.ago.to_formatted_s(:db) }
  e.date_created  { Time.now.to_formatted_s(:db) }
  e.association   :creator, :factory => :user
  e.association   :provider_id, :factory => :user
  e.association   :patient_id, :factory => :user
  e.association   :location
  e.association   :encounter_type
end

Factory.define :encounter_type do |e|
  e.name          "HIV First visit"
  e.date_created  { Time.now.to_formatted_s(:db) }
  e.association   :creator, :factory => :user
end

Factory.define :location do |l|
  l.name          "Chinthembwe Health Centre"
  l.date_created  { Time.now.to_formatted_s(:db) }
  l.association   :creator, :factory => :user
  l.description   "Private Health Facility"
end

Factory.define :order do |o|
  o.date_created  { Time.now.to_formatted_s(:db) }
  o.association   :creator, :factory => :user
  o.association   :encounter
  o.association   :order_type
  o.voided        false
end

Factory.define :order_type do |ot|
  ot.date_created  { Time.now.to_formatted_s(:db) }
  ot.association   :creator, :factory => :user
  ot.name          "Give drugs"
end

Factory.define :user do |u|
  u.salt          { User.random_string(10) }
  u.password      { |a| User.encrypt(Sham.password, a.salt) }
  u.date_created  { Time.now.to_formatted_s(:db) }
  u.date_changed  { Time.now.to_formatted_s(:db) }
  u.date_voided   { Time.now.to_formatted_s(:db) }
  u.voided        false
  u.username      { Sham.username }
  u.system_id     "Baobab Admin"
  u.first_name    { Sham.first_name }
  u.last_name     { Sham.last_name }
end
