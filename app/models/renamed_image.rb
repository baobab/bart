class RenamedImage < ActiveRecord::Base

  def padded_arv_number(num = 4)
    "%0#{num}d" % self.arv_number
  end
  
  # save md5sums for each renamed file and rename un-renamed files using existing md5sums
  def self.update_images(image_path)
    site_code = Location.current_arv_code
    Dir.foreach(image_path) do |filename|
      next if filename =~ /^\./
      md5sum = `md5sum #{image_path}/#{filename} | awk {'print $1'}`
      md5sum = md5sum.slice(0,32)
      renamed_image = RenamedImage.find_by_md5sum(md5sum)
      
      if renamed_image && !(filename =~ /^#{site_code}/)
        src = "#{image_path}/#{filename}"
        dest = "#{image_path}/#{site_code}#{renamed_image.padded_arv_number}-#{renamed_image.page_number}.jpg"
        puts "Renaming #{src} to #{dest}"
        `mv #{src} #{dest}`
      elsif !renamed_image && filename =~ /^#{site_code}/
        arv_number  = $1 if filename =~ /[A-Z]+([0-9]+)-[0-9]\./
        page_number = $1 if filename =~ /[A-Z]+[0-9]+-([0-9])\./

        renamed_image = RenamedImage.new(:md5sum => md5sum, 
                                          :arv_number => arv_number.to_i,
                                          :page_number => page_number.to_i)
        renamed_image.save
      end
    end

  end
end
    
