require 'fileutils'

FileUtils.rm File.join(Rails.root, "script", "db_setup")

FileUtils.rm File.join(Rails.root, ProductionDataHelpers::RELATIVE_CONFIG_PATH)
