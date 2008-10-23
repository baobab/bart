require 'spec_statistics'

namespace :spec do
  desc "Report code statistics on the application and specs code"
  task :stats do
    stats_directories = {
        "Specs" => "spec",
        "Application" => "app"
      }.map {|name, dir| [name, "#{Dir.pwd}/#{dir}"]}
    SpecStatistics.new(*stats_directories).to_s
  end
end


