require 'fileutils'
require File.join(File.dirname(__FILE__), "lib", "production_data_helpers.rb")

rails_root = File.join(File.dirname(__FILE__), '..', '..', '..')

puts
relative_db_setup_path = File.join("script", "db_setup")
dest_db_setup = File.join(rails_root, relative_db_setup_path)
if File.exist?(dest_db_setup)
  puts "db_setup was already installed to #{relative_db_setup_path}, check it out and edit it appropriately"
else
  FileUtils.cp File.join(File.dirname(__FILE__), relative_db_setup_path), dest_db_setup
  puts "db_setup installed to #{relative_db_setup_path}, check it out and edit it appropriately"
end

puts
dest_production_data_config = File.join(rails_root, ProductionDataHelpers::RELATIVE_CONFIG_PATH)
if File.exist?(dest_production_data_config)
  puts "Production Data config was already installed to #{ProductionDataHelpers::RELATIVE_CONFIG_PATH}, check it out and edit it appropriately"
else
  FileUtils.cp File.join(File.dirname(__FILE__), ProductionDataHelpers::RELATIVE_CONFIG_PATH), dest_production_data_config
  puts "Example config installed to #{ProductionDataHelpers::RELATIVE_CONFIG_PATH}, check it out and edit it appropriately"
end

puts
puts "Installation Complete, have a README:"
puts
puts File.read(File.join(File.dirname(__FILE__), "README"))
puts
