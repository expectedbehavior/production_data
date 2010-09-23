require 'fileutils'
require File.join(File.dirname(__FILE__), "lib", "production_data_helpers.rb")

relative_db_setup_path = File.join("script", "db_setup")
dest_db_setup = File.join(RAILS_ROOT, relative_db_setup_path)
if File.exist?(dest_db_setup)
  puts
  puts "db_setup installed to #{relative_db_setup_path}, check it out and edit it appropriately"
else
  FileUtils.cp File.join(File.dirname(__FILE__), relative_db_setup_path), dest_db_setup
end

dest_production_data_config = File.join(RAILS_ROOT, ProductionDataHelpers::RELATIVE_CONFIG_PATH)
if File.exist?(dest_production_data_config)
  puts
  puts "Example config installed to #{ProductionDataHelpers::RELATIVE_CONFIG_PATH}, check it out and edit it appropriately"
else
  FileUtils.cp File.join(File.dirname(__FILE__), ProductionDataHelpers::RELATIVE_CONFIG_PATH), dest_production_data_config
end

puts
puts "Installation Complete, have a README:"
puts
puts File.read(File.join(File.dirname(__FILE__), "README"))
puts
