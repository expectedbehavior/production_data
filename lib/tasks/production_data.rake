#!/usr/bin/env ruby
require "yaml"
require 'erb'
require 'zlib'

require File.join(File.dirname(__FILE__), "..", "production_data_helpers.rb")
include ProductionDataHelpers

GET_DATA_EVERY = 60 * 60 * 12 # once every 12 hours

namespace :production_data do
  desc "convenience task for getting and importing production data"
  task :get_and_import_data => ['production_data:get_data', 'production_data:import_data']
  
  namespace :get_and_import_data do
    [:production, :staging].each do |from_env|
      desc "grabs recent #{from_env} data and loads it into your development db"
      task from_env => ["production_data:get_data:#{from_env}", "production_data:import_data:#{from_env}"]
    end
  end

  desc "convenience task for getting production data"
  task :get_data => ['production_data:get_data:production']

  namespace :get_data do
    [:production, :staging].each do |from_env|
      desc "grabs recent #{from_env} data"
      task from_env do
        last_time = Time.now.to_f - (newest_db_file_time(source_db_config(from_env), from_env) || 0).to_f

        get_data_cmd = "cap #{from_env} production_data:db:dump_to_local"
        if GET_DATA_EVERY < last_time
          system get_data_cmd  or fail "Error getting production data. #{$?.inspect}"
        else
          puts
          puts "Got #{from_env} data #{(last_time / 60).round} minutes ago (~#{(last_time / 60 / 60).round} hours), so we'll use it instead of getting fresh"
          puts "run '#{get_data_cmd}' if you really need the good stuff"
          puts
        end
      end
    end
  end

  desc "imports tmp/<whatever>.sql into dev DB"
  task :import_data => ['production_data:import_data:production']

  namespace :import_data do
    [:production, :staging].each do |from_env|
      desc "imports tmp/<whatever>.sql into dev DB"
      task from_env do
        to_db_config = destination_db_config
        from_db_config = source_db_config(from_env)
        
        db_file_path = newest_db_file_path(from_db_config, from_env) || fail("Missing db file to import.")
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
    end
  end

  desc "reads the latest db dump, filters, and writes it to a file"
  task :print_filtered_dump_to_file => ['production_data:print_filtered_dump_to_file:production']

  namespace :print_filtered_dump_to_file do
    [:production, :staging].each do |from_env|
      desc "reads the latest db dump, filters, and writes it to a file"
      task :print_filtered_dump_to_file do
        new_file = ENV["FILE"]
        unless new_file
          puts "must provide FILE arg"
          exit 1
        end
        
        to_db_config = destination_db_config
        from_db_config = source_db_config(from_env)
        
        db_file_path = newest_db_file_path(from_db_config, from_env) || fail("Missing db file to import.")
        catter = db_catter(db_file_path)
        
        puts "dumping #{db_file_path} to #{new_file}..."
        File.open(new_file, "w") do |file|
          filter_lines_and_apply!(IO.popen("#{catter} #{db_file_path}"), from_db_config, to_db_config) { |line| file.write line }
        end
      end
    end
  end
end

# shortcuts
namespace :pd do
  desc "convenience task for getting and importing production data"
  task :gid => ['production_data:get_and_import_data']
  namespace :gid do
    desc "grabs recent production data and loads it into your development db"
    task :prod => ['production_data:get_and_import_data:production']
    desc "grabs recent staging data and loads it into your development db"
    task :staging => ['production_data:get_and_import_data:staging']
  end
  desc "convenience task for getting production data"
  task :gd => ['production_data:get_data']
  namespace :gd do
    desc "grabs recent production data"
    task :prod => ['production_data:get_data:production']
    desc "grabs recent staging data"
    task :staging => ['production_data:get_data:staging']
  end
  desc "imports tmp/<whatever>.sql into dev DB"
  task :id => ['prodcution_data:import_data']
  namespace :id do
    desc "imports tmp/<whatever>.sql into dev DB"
    task :prod => ['prodcution_data:import_data:production']
    desc "imports tmp/<whatever>.sql into dev DB"
    task :staging => ['prodcution_data:import_data:staging']
  end
end

## these are just here so we're backwards compatible
desc "grabs recent production data and loads it into your development db"
task :get_production_data => ['production_data:get_data:production']

desc "imports tmp/<whatever>.sql into dev DB"
task :import_production_data => ['production_data:import_data']

desc "convenience task for getting and importing production data"
task :get_and_import_production_data => ['get_production_data', 'import_production_data']

desc "reads the latest db dump, filters, and writes it to a file"
task :print_filtered_dump_to_file => ['production_data:print_filtered_dump_to_file']
