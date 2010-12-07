require 'fileutils'
require 'erb'

class MultiserverWheneverizer
  def run!
    write_config!
    copy_whenever_files!
  end
  
  def write_config!
    FileUtils.mkdir_p("config")
    File.open("config/whenever.yml", 'w') { |f| f.puts custom_config }
  end
  
  def copy_whenever_files!
    FileUtils.mkdir_p("config/whenever")
    FileUtils.cp_r("#{gem_root}/templates/config/whenever/.", "config/whenever")
  end
  
  def custom_config
    ERB.new(File.read("#{gem_root}/templates/config/whenever.yml")).result(binding)
  end
  
  def hostname
    `hostname`.strip
  end
  
  private
  
  def gem_root
    @gem_root ||= File.expand_path File.dirname(File.dirname(__FILE__))
  end
  

end