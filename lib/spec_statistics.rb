require 'code_statistics' #borrow from http://dev.rubyonrails.org/svn/rails/trunk/railties/lib/code_statistics.rb
class SpecStatistics < CodeStatistics

  TEST_TYPES << "Specs"

  private
  def calculate_directory_statistics(directory, pattern = /.*\.rb$/)
    stats = { "lines" => 0, "codelines" => 0, "classes" => 0, "methods" => 0, "specs" => 0, "behaviors" => 0 }


    Dir.foreach(directory) do |file_name| 
      if File.stat(directory + "/" + file_name).directory? and (/^\./ !~ file_name)
        newstats = calculate_directory_statistics(directory + "/" + file_name, pattern)
        stats.each { |k, v| stats[k] += newstats[k] }
      end

      next unless file_name =~ pattern

      f = File.open(directory + "/" + file_name)

      while line = f.gets
        if line =~ /=begin/
          block_commented_code = true if line =~ /=begin/
        elsif line =~ /=end/
          block_commented_code = false
        end

        stats["lines"]     += 1
        next if block_commented_code || line =~ /^\s*#/ || line =~ /=end/

        stats["classes"]   += 1 if line =~ /class [A-Z]/
        stats["methods"]   += 1 if line =~ /def\s*[a-zA-Z]/
        stats["specs"]     += 1 if line.strip =~ /^it.*(do|\{)$/
        stats["behaviors"] += 1 if line =~ /describe.*(do|\{)$/
        stats["codelines"] += 1 unless line =~ /^\s*$/ || line =~ /^\s*#/
      end
    end

    stats
  end

  def calculate_total
    total = { "lines" => 0, "codelines" => 0, "classes" => 0, "methods" => 0, "specs" => 0, "behaviors" => 0 }
    @statistics.each_value { |pair| pair.each { |k, v| total[k] += v } }
    total
  end

  def print_header
    print_splitter
    puts "| Name                 | Lines |   LOC | Classes | Methods | Behaviors | Specifications | M/C | LOC/M | S/B |"
    print_splitter
  end

  def print_splitter
    puts "+----------------------+-------+-------+---------+---------+-----------+----------------+-----+-------+-----+"
  end

  def print_line(name, statistics)
    m_over_c   = (statistics["methods"] / statistics["classes"])   rescue m_over_c = 0
    loc_over_m = (statistics["codelines"] / statistics["methods"]) - 2 rescue loc_over_m = 0
    
    s_over_b = (statistics["specs"] / statistics["behaviors"]) rescue 0
    
    start = if TEST_TYPES.include? name
      "| #{name.ljust(20)} "
    else
      "| #{name.ljust(20)} "
    end

    puts start + 
         "| #{statistics["lines"].to_s.rjust(5)} " +
         "| #{statistics["codelines"].to_s.rjust(5)} " +
         "| #{statistics["classes"].to_s.rjust(7)} " +
         "| #{statistics["methods"].to_s.rjust(7)} " +
         "| #{statistics["behaviors"].to_s.rjust(10)}" +
         "| #{statistics["specs"].to_s.rjust(15)}" +
         "| #{m_over_c.to_s.rjust(3)} " +
         "| #{loc_over_m.to_s.rjust(6)}" +
         "| #{s_over_b.to_s.rjust(3)} |"
  end
end

