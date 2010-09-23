require 'fileutils'

FileUtils.cp File.join(File.dirname(__FILE__), "config", "production_data.yml"), File.join(RAILS_ROOT, "config", "production_data.yml")

puts
puts "Example config installed to config/production_data.yml, check it out and edit it appropriately"
puts
