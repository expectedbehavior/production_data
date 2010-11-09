#!/usr/bin/env ruby
require "yaml"
require 'erb'
require 'zlib'

require File.join(File.dirname(__FILE__), "..", "production_data_helpers.rb")
include ProductionDataHelpers

LAST_GET_PRODUCTION_DATA_TIME_FILE = File.join(RAILS_ROOT, "tmp", "last_get_production_data_time.tmp")
FileUtils.mkdir_p File.dirname(LAST_GET_PRODUCTION_DATA_TIME_FILE)
GET_PRODUCTION_DATA_EVERY = 60 * 60 * 12 # once every 12 hours

desc "grabs recent production data and loads it into your development db"
task :get_production_data do

  last_time = Time.now.to_f - (File.open(LAST_GET_PRODUCTION_DATA_TIME_FILE) {|f| f.read} rescue "0").chomp.to_i

  if GET_PRODUCTION_DATA_EVERY < last_time

    system "cap production production_data:db:dump_to_local" or fail "Error getting production data. #{$?.inspect}"
    File.open(LAST_GET_PRODUCTION_DATA_TIME_FILE, "w") {|f| f.write(Time.now.to_f.to_s)}

  else

    time_file_name = File.basename(LAST_GET_PRODUCTION_DATA_TIME_FILE)
    puts
    puts "Got production data #{(last_time / 60).round} minutes ago (~#{(last_time / 60 / 60).round} hours), so we'll use it instead of getting fresh"
    puts "remove the file '#{time_file_name}' from tmp if you really need the good stuff"
    puts

  end

end

desc "imports tmp/<whatever>.sql into dev DB"
task :import_production_data do
  to_db_config = destination_db_config
  from_db_config = source_db_config
  
  db_file_path = newest_db_file_path(from_db_config)
  catter = db_catter(db_file_path)
  
  to_username = to_db_config[RAILS_ENV]['username']
  to_password = to_db_config[RAILS_ENV]['password']
  to_database = to_db_config[RAILS_ENV]['database']
  
  initialize_db
  
  puts "importing #{db_file_path}..."
  IO.popen("mysql -u #{to_username} -p'#{to_password}' #{to_database}", "w") do |mysql|
    filter_lines_and_apply!(IO.popen("#{catter} #{db_file_path}"), from_db_config, to_db_config) { |line| mysql.write line }
  end
end

desc "convenience task for getting and importing production data"
task :get_and_import_production_data => ['get_production_data', 'import_production_data']


desc "reads the latest db dump, filters, and writes it to a file"
task :print_filtered_dump_to_file do
  new_file = ENV["FILE"]
  unless new_file
    puts "must provide FILE arg"
    exit 1
  end
  
  to_db_config = destination_db_config
  from_db_config = source_db_config
  
  db_file_path = newest_db_file_path(from_db_config)
  catter = db_catter(db_file_path)
  
  puts "dumping #{db_file_path} to #{new_file}..."
  File.open(new_file, "w") do |file|
    filter_lines_and_apply!(IO.popen("#{catter} #{db_file_path}"), from_db_config, to_db_config) { |line| file.write line }
  end
end
