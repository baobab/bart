#!/usr/bin/ruby

def print_usage
  puts "Usage: track_renamed_files.rb <src-dir>"
  puts " e.g.: track_renamed_files.rb /var/www/mc1"
end

if ARGV.length < 1
  print_usage
  exit
end

dir = ARGV.last
RenamedImage.update_images(dir)

