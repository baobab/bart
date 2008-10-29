#!/usr/bin/ruby
# shows number of specs out of total number of methods written per model/controller (sort of)
#
# sort of because the spec could be pending
#
# Examples:
#         script/spec_progress_in.rb patient model
#         script/spec_progress_in.rb patient controller
#
# KNOWN ISSUES:
#   1. Models in sub-directories are not supported

def get_stats(file, type='model')
  if type == 'model'
    specs = `grep "it " spec/#{type}s/#{file}_spec.rb |wc -l`
    methods = `grep "def " app/#{type}s/#{file}.rb |wc -l`
  else
    specs = `grep "it " spec/#{type}s/#{file}_#{type}_spec.rb |wc -l`
    methods = `grep "def " app/#{type}s/#{file}_#{type}.rb |wc -l`
  end

  specs.gsub!("\n",'')
  "specs/methods: #{specs}/#{methods}"
end

if ARGV.length < 2
  puts "Specs written out of total methods"
  puts "Usage: script/spec_progress_in.rb <name> <type>"
  puts " e.g.: script/spec_progress_in.rb encounter model"
  puts "       script/spec_progress_in.rb patient controller"
  exit
end

puts get_stats(ARGV[0], ARGV[1])

