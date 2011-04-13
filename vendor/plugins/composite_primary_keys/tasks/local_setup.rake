namespace :local do
  desc 'Copies over the same local files ready for editing'
  task :setup do
    sample_files = Dir[File.join(File.expand_path(".."), "local/*.rb.sample")]
    sample_files.each do |sample_file|
      file = sample_file.sub(".sample","")
      unless File.exists?(file)
        puts "Copying #{sample_file} -> #{file}"
        sh %{ cp #{sample_file} #{file} }
      end
    end
  end
end