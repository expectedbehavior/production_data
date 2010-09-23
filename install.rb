require 'fileutils'

FileUtils.cp File.join(File.dirname(__FILE__), "script", "db_setup"), File.join(RAILS_ROOT, "script", "db_setup")

FileUtils.cp File.join(File.dirname(__FILE__), ProductionDataHelpers::RELATIVE_CONFIG_PATH), File.join(RAILS_ROOT, ProductionDataHelpers::RELATIVE_CONFIG_PATH)

puts
puts "Example config installed to #{ProductionDataHelpers::RELATIVE_CONFIG_PATH}, check it out and edit it appropriately"
puts
