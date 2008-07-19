require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/encounter_spec'

require 'net/smtp'

# Need to do some crazy hacking stubbing stuff to test backtick results
module Kernel
  alias_method :backtick, :'`'

  # $shell_result is used to stub the results of a backtick call
  def `(cmd)
    $shell_result
  end
end

describe Success do
  fixtures :location  

  before(:each) do
    Net::SMTP.stub!(:start).and_return(true)
    Success.sent_alert = false
  end

  it "should verify the success of the site" do
    $shell_result = '' # This will cause a problem and force an alert to be sent
    Success.verify
    Success.sent_alert.should == true
  end

  it "should not verify if an alert has recently been sent" do
    Success.set_global_property("last_error_reported", 1.minute.ago)
    Success.verify
    Success.sent_alert.should == false
  end

  it "should reset last_error_reported property" do
    Success.set_global_property("last_error_reported", 1.minute.ago)
    Success.reset
    GlobalProperty.find_by_property("last_error_reported").property_value.should be_blank
  end

  it "should check for recent alerts" do
    Success.set_global_property("last_error_reported", 11.minute.ago)
    Success.sent_recent_alert?.should == false
    Success.set_global_property("last_error_reported", 1.minute.ago)
    Success.sent_recent_alert?.should == true
  end

  it "should check if the clinic is active" do

    Success.clinic_hours = nil
    Success.clinic_breaks = nil
    Success.clinic_is_active?.should == true

    Success.clinic_hours=() # Use the default
    Success.clinic_breaks=("10:30am-11:00am") 
    Time.stub!(:now).and_return(Time.parse("10:45am"))
    Success.clinic_is_active?.should == false

    Success.clinic_hours=("8am-5pm") 
    Success.clinic_breaks=("10:30am-11:00am") 
    Time.stub!(:now).and_return(Time.parse("2:00pm"))
    Success.clinic_is_active?.should == true

    Time.stub!(:now).and_return(Time.parse("7:00pm"))
    Success.clinic_is_active?.should == false
  end

  it "should set the clinic hours" do
    Success.clinic_hours=("beer-thirty") 
    GlobalProperty.find_by_property("clinic_hours").property_value.should == "beer-thirty"
  end

  it "should set the clinic breaks" do
    Success.clinic_breaks=("beer-thirty") 
    GlobalProperty.find_by_property("clinic_breaks").property_value.should == "beer-thirty"
  end

  it "should set the smtp server" do 
    Success.smtp_server=("beer-thirty") 
    GlobalProperty.find_by_property("smtp_server").property_value.should == "beer-thirty"
  end

  it "should be able to create and update global properties" do
    Success.set_global_property("muppetballs", "fluffy")
    GlobalProperty.find_by_property("muppetballs").property_value.should == "fluffy"
    Success.set_global_property("muppetballs", "furry")
    GlobalProperty.find_by_property("muppetballs").property_value.should == "furry"
  end

  it "should get the current location" do
    Success.set_global_property("current_health_center_id", Location.current_location.id)
    Success.current_location.should == Location.current_location.name
  end

  it "should get the current IP address" do
    command_line_ip = backtick("ifconfig | grep 'inet ' | grep -v '127.0.0.1' | grep -v '192.168.2.1'").match(/inet (addr)?:?([^\s]*)/)[0].split(/(:|\s)/).last
    command_line_ip.should == Success.current_ip_address
  end

  it "should send email" do
    Success.alert("My feet have smoking")
  end

end


describe Success, "Tasks" do

  before(:each) do
    Net::SMTP.stub!(:start).and_return(true)
    Success.sent_alert = false

  end

  it "should check for recent encounters and alert when there are none" do
    Success.should_have_recent_encounter
    Success.sent_alert.should == true
  end

  it "should check for recent encounters and not alert when there is one" do
    encounter = create_sample(Encounter, :encounter_datetime => 1.minute.ago)
    Success.should_have_recent_encounter
    Success.sent_alert.should == false
  end

  it "should send alert when there is no login screen" do
    $shell_result = "404"
    Success.should_have_a_login_screen
    Success.sent_alert.should == true
  end

  it "should not send alert when there is login screen" do
    $shell_result = <<EOF
                             Loading User Login

   Username ______________________________
   Password ______________________________
   Submit

                    Verifying your username and password

                              Please wait......
EOF
    Success.should_have_a_login_screen
    Success.sent_alert.should == false
  end

  it "should have lynx installed" do
    lynx = backtick('which lynx')
    lynx.match(/lynx/).should_not == nil
  end

  it "should send alert when there are no running mongrels" do
    $shell_result = ""
    Success.should_have_3_mongrels
    Success.sent_alert.should == true
  end

  it "should send alert when there are only two running mongrels" do
    $shell_result = "12121\n3222"
    Success.should_have_3_mongrels
    Success.sent_alert.should == true
  end

  it "should not send alert when there are enough running mongrels" do
    $shell_result = "12121\n3222\n55442"
    Success.should_have_3_mongrels
    Success.sent_alert.should == false
  end

  it "should send alert when machine is not hot" do
    $shell_result = "temperature:             54 C\n"
    Success.should_not_run_hot
    Success.sent_alert.should == false
  end

  it "should send alert when machine is hot" do
    $shell_result = "temperature:             66 C\n"
    Success.should_not_run_hot
    Success.sent_alert.should == true
  end

  it "should send alert when there is not enough free memory" do
    $shell_result = "MemFree:         40736 kB\n" 
    Success.should_have_free_memory
    Success.sent_alert.should == true
  end

  it "should not send alert when there is enough free memory" do
    $shell_result = "MemFree:         640736 kB\n" 
    Success.should_have_free_memory
    Success.sent_alert.should == false
  end

  it "should not send alert if free disk space is high" do
    $shell_result =  "/dev/sda6             19228276   3688924  14562604  21% /var\n"
    Success.should_have_free_disk_space
    Success.sent_alert.should == false
  end

  it "should send alert if free disk space is low" do
    $shell_result =  "/dev/sda6             19228276   3688924  1456  21% /var\n"
    Success.should_have_free_disk_space
    Success.sent_alert.should == true
  end

  it "should not send alert if more than one day uptime" do
    $shell_result =  "244098.90 90781.20"
    Success.should_have_more_than_ten_minutes_uptime
    Success.sent_alert.should == false
  end

  it "should send alert if less than one day uptime" do
    $shell_result =  "0.38 0.47 0.40 1/315 24294\n"
    $shell_result =  "500 40"
    Success.should_have_more_than_ten_minutes_uptime
    Success.sent_alert.should == true
  end

  it "should send alert if load average is over 1.5" do
    $shell_result =  "2.38 2.47 2.40 1/315 24294\n"
    Success.should_have_low_load_average
    Success.sent_alert.should == true
  end

  it "should not send alert if load average is less than 1.5" do
    $shell_result =  "1.38 1.47 1.40 1/315 24294\n"
    Success.should_have_low_load_average
    Success.sent_alert.should == false
  end

  it "should get the end of the log file" do
    $shell_result = "blah blah blah"
    Success.get_recent_log.should == "blah blah blah"
  end

  it "should run Success in the cron tab" do
    backtick("crontab -l").match(/Success.verify/).should != nil
  end


end
