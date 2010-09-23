require 'yaml'
module ProductionDataHelpers

  CONFIG_FILE = File.join(RAILS_ROOT, "config", "production_data.yml")
#   CONFIG_FILE = File.join(File.dirname(__FILE__), "..", "..", "..", "..", "config", "production_data.yml")
  DEFAULT_CONFIG = {
    'email_filter_exclusions' => [],
    'filtered_email_address' => 'test+{{filtered_email}}@example.com'
  }

  #                               |-| gobble escaped quotes so we don't end up removing the '\' that was escaping it
  EMAIL_REGEXP = /[^ ']+@[^ ']+\.(\\'|[^ '])+/i

  def filter_lines_and_apply!(str, from_db_config, to_db_config, &block)
    i = 0
    str.each_line do |line|
      # don't calculate percent because we don't want to read all of the IO up front
      if (i += 1) % 1000 == 0
        print "\r#{i} lines imported"
        $stdout.flush
      end
      
      if line =~ /^insert into/i # line has data that we might escape
        filter_emails!(line)
      end
      
      # don't do this for EY
      filter_credentials!(line, from_db_config, to_db_config)
      
      block.call line
    end
    puts "\nfinished"
  end

  def configuration
    @production_data_configuration ||=
      begin
        config = if File.exist?(CONFIG_FILE)
          YAML.load_file(CONFIG_FILE)
        else
          {}
        end
        DEFAULT_CONFIG.merge config
      end
  end

  def db_catter(filename)
    case filename
      when /\.gz$/  : "zcat"
      when /\.bz2$/ : "bzcat"
      else            "cat"
    end
  end
  
  def newest_db_file_path(db_config)
    # we specified the file to use on the command line, or...
    p = ENV['DB_BACKUP_FILE'] ||
      Dir["tmp/#{db_config["production"]["database"]}*"].sort_by do |x|
        # use the datetime in the filename to get the most recent (possibly without seconds)
        dateish_string = x.match( /.*(\d\d\d\d)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d+)\D+(\d*)\D+/ )
        date_ints = dateish_string[1, 6].map { |s| s.to_i } # we don't want to load all of rails, so no Symbol#to_proc
        Time.local(*date_ints)
      end.last
    fail "missing a file to import.\nnewest database file: #{p}" unless p
    p
  end

  def initialize_db
    cmd = <<-CMD
      cd #{RAILS_ROOT} &&
        ruby script/db_setup -e #{RAILS_ENV}
    CMD
    puts "initializing DB with command: \n#{cmd}"
    system cmd or fail "Error importing production data with command: \n#{cmd}"
  end

  def filter_credentials!(line, from_db_config, to_db_config)
    line.gsub!(/`#{from_db_config['production']['username']}`/, "`#{to_db_config[RAILS_ENV]['username']}`")
    line.gsub!(/`#{from_db_config['production']['database']}`/, "`#{to_db_config[RAILS_ENV]['database']}`")
  end

  def filter_emails!(line)
    line.gsub!(EMAIL_REGEXP) do |s|
      if ENV['KEEP_EMAILS'] || configuration['email_filter_exclusions'].detect { |exclude| exclude.match s }
        s
      else
        configuration['filtered_email_address'].sub('{{filtered_email}}', strip_email_for_import(s))
      end
    end
  end

  def strip_email_for_import(s)
    s.gsub(/\W/, '.') # replace all non alpha-num characters with .
  end
  
  class MissingDatabaseConfigException < Exception; end

  def database_config_from_production
    @database_config_from_production ||=
      begin
        config_path = File.join("tmp", "production_db_config.yml")
        
        unless system "cap production dump_database_config_from_production_to_tmp"
          puts "WARNING: couldn't get production config at the moment"
          if File.exist? config_path
            puts "Previously downloaded config data found, using it"
          else
            raise MissingDatabaseConfigException.new("ERROR: couldn't find previously downloaded config data")
          end
        end
        YAML.load(File.open(config_path) { |f| f.read })
      end
  end
  
  def source_db_config
    begin
      database_config_from_production
    rescue MissingDatabaseConfigException
      puts "couldn't find production config, using destination db config for import replacement."
      destination_db_config
    end
  end
  
  def destination_db_config
    YAML.load(ERB.new(File.open(File.join(RAILS_ROOT, "config", "database.yml")) {|f| f.read}).result(binding))
  end
  
end
