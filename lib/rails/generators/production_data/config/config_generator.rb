module ProductionData
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      desc 'Creates a ProductionData gem configuration file at config/production_data.yml'

      def self.source_root
        @_production_data_source_root ||= File.expand_path("../templates", __FILE__)
      end

      def create_config_file
        template 'production_data.yml', File.join('config', 'production_data.yml')
      end
    end
  end
end
