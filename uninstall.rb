require 'fileutils'

FileUtils.rm File.join(RAILS_ROOT, "script", "db_setup")

FileUtils.rm File.join(RAILS_ROOT, ProductionDataHelpers::RELATIVE_CONFIG_PATH)
