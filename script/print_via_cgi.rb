#!/usr/bin/ruby
# The print_string is the actual command to be sent to the printer
# Because the iopener web server can only accept GETs of limited size
# We have to send multiple GETs and tell the iopener when we are done

#destination = "192.168.5.113:81"
log = File.open("/tmp/print_log", "a")
log.puts("Started with #{ARGV.join('|')}")

if ARGV[1].nil?
  if ENV["DISPLAY"].nil?
    log.puts "No destination or DISPLAY set" 
    exit
  end
  destination = ENV["DISPLAY"].split(":").first unless ENV["DISPLAY"].nil?
else
  destination = ARGV[1]
end

log.puts destination

port = "81"
url = "http://#{destination}:#{port}/cgi-bin/print.sh"
#wget_command = "wget -q --output-document=/dev/null"
wget_command = "wget --output-document=/dev/null"

file = File.open(ARGV[0])
whole_string = file.read


index=0
max_length = 60
sent_string = ""
commands = ""
while true
  end_point = index + max_length
  current_slice = whole_string[index..end_point]
  end_of_string = end_point > whole_string.length
  if end_of_string
    mode = "finish"
  elsif index == 0
    mode = "start"
  else
    mode = "continue"
  end


# Stupid hack to fix lines ending with newlines which don't seem to get handled right on the popper
  current_slice = current_slice + " " if current_slice =~ /\n$/


  command = "#{wget_command} \'#{url}?mode=#{mode}&print_string=#{current_slice}\'"
#  puts command
  commands << command + "\n"
#  puts command
#  puts `#{command}`
`#{command}`

  sent_string << current_slice

  break if end_of_string
  index+=max_length+1
end

log.puts sent_string
log.puts commands
log.puts "Finished"

exit
