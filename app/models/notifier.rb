class Notifier < ActionMailer::Base
SYSTEM_EMAIL_ADDRESS = %{"Error Notifier" <error.notifier@myapp.com>}
EXCEPTION_RECIPIENTS = %w{jintha@gmail.com thamwa@gmail.com soyapi@gmail.com mike@vdomck.org jinthani@yahoo.com}
  
  def exception_notification(controller, request,
                           exception, sent_on=Time.now)
    @subject    = sprintf("[ERROR] %s\#%s (%s) %s",
                        controller.controller_name,
                        controller.action_name,
                        exception.class,
                        exception.message.inspect)
    @body       = { "controller" => controller, "request" => request,
                  "exception" => exception,
                  "backtrace" => sanitize_backtrace(exception.backtrace),
                  "host" => request.env["HTTP_HOST"],
                  "rails_root" => rails_root }
    @sent_on    = sent_on
    @from       = SYSTEM_EMAIL_ADDRESS
    @recipients = EXCEPTION_RECIPIENTS
    @headers    = {}
  end
  
  private
  def sanitize_backtrace(trace)
   re = Regexp.new(/^#{Regexp.escape(rails_root)}/)
   trace.map do |line|
     Pathname.new(line.gsub(re, "[RAILS_ROOT]")).cleanpath.to_s
   end
  end

  def rails_root
    @rails_root ||= Pathname.new(RAILS_ROOT).cleanpath.to_s
  end

  def signup_thanks
    # Email header info MUST be added here
     @recipients = ["jintha@gmail.com","mike@vdomck.org","soyapi@gmail.com","thamwa@gmail.com","jinthani@yahoo.com"]
     @from = "baobab.bart@gmail.com"
     @subject = "Thank you for registering with our website" 

    # Email body substitutions go here
     @body["first_name"] = "Oliver"
     @body["last_name"] = "Gadabu"
  end
 
  def daily_report
  #should report total number of visits that day
  #should break down visits by sex and age group
  #should report on total patients initiated and the conditions of initiation
    
    # Email header info MUST be added here
     @recipients = ["jintha@gmail.com","mike@vdomck.org","soyapim@gmail.com","thamwa@gmail.com","jinthani@yahoo.com"]
     @from = "baobab.bart@gmail.com"
     @subject = "Thank you for registering with our website" 

  #e-mail body substitutions 
   @body["female_encounters"] = Encounter.find_by_sql("Select count(*) from patient left join encounter using(patient_id) where patient.gender='Female'and left(encounter.encounter_datetime,10)= left(now(),10)").first
   @body["male_encounters"] = Encounter.find_by_sql("Select count(*) from patient left join encounter using(patient_id) where patient.gender='Male' and left(encounter.encounter_datetime,10)= left(now(),10)").first
  @body["todays_encounters"] = Encounter.find_by_sql("Select count(*) from patient left join encounter using(patient_id) where left(encounter.encounter_datetime,10)= left(now(),10)").first

   
  end
 end 


