require 'yaml'

class MultiserverWhenever
  def initialize(set_vars = {})
    defaults = {:environment => 'production'}
    @set_vars = defaults.merge(set_vars)
  end
  
  def clear!
    current_whenever_identifiers.each do |identifier|
      whenever_with_vars "--load-file #{dummy_whenever_path} --clear-crontab #{identifier}"
    end
  end
  
  def write!
    roles.each do |role|
      relative_path = "config/whenever/#{role}.rb"
      absolute_path = File.expand_path(relative_path)
      whenever_with_vars "--load-file #{relative_path} --update-crontab #{absolute_path}"
    end
  end
  
  def current_whenever_identifiers
    @identifiers ||= parse_identifiers
  end
  
  def read_cron
    command("crontab -l")
  end
  
  def roles
    [config[hostname]].flatten.compact
  end
  
  def config
    @config ||= YAML.load(read_config)
  end
  
  def read_config
    File.read("config/whenever.yml")
  end
  
  def hostname
    command('hostname')
  end
  
  # So for some reason, the whenever command requires that the
  # --load-file argument be passed, even if you are using the
  # --clear-crontab argument to clear out outdated crontabs.
  # 
  # The problem is that you may need to clear out old crontab 
  # data from cron that was generated by a whenever file that
  # no longer exists, so you can't use it for the --load-file
  # argument. As it's unnecessary anyways, I'm just going to use
  # the config/whenever/do_not_remove.rb file anytime we're 
  # clearing crontabs out. It's an "empty" file, but we need
  # to keep it around.
  # 
  def dummy_whenever_path
    "config/whenever/do_not_remove.rb"
  end
  
  # Only worry about whenever blocks for this project
  def parse_identifiers
    lines = read_cron.split("\n")
    root_dir = Dir.pwd
    puts "Root Dir is : #{root_dir}"
    lines = lines.select {|line| line =~ /^# Begin Whenever generated tasks for: #{root_dir}/ }
    lines.map {|line| line.gsub("# Begin Whenever generated tasks for: ", '') }
  end
  
  private
  
  def whenever_with_vars(opts)
    unless @set_vars.empty?
      query_string = @set_vars.inject([]) {|arr, tuple| arr << "#{tuple.first}=#{tuple.last}"}.join("&")
      opts << " --set #{query_string}"
    end
    whenever(opts)
  end
  
  def whenever(opts)
    cmd = "whenever #{opts}"
    puts cmd
    %x{#{cmd}}
  end
  
  def command(cmd)
    %x{#{cmd}}.strip
  end
  
end