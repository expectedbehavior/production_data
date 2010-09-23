require 'test/unit'
require 'fileutils'
require 'yaml'
require 'erb'
require 'rubygems'
require 'highline/import'

class DbSetupTest < Test::Unit::TestCase # ActiveSupport::TestCase

  SCRIPT_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', 'script', 'db_setup'))
  FAKE_APP_PATH = File.expand_path(File.join(File.dirname(__FILE__), 'fake_app'))
  FAKE_DB_CONFIG_PATH = File.join(FAKE_APP_PATH, 'config', 'database.yml')
#   ROOT_PW = ask("gimme root sql password: ") { |q| q.echo = false}
  
  def test_usual_first_run__create_dbs_from_db_yml
    setup_test_app
    FileUtils.cd FAKE_APP_PATH do
      drop_dbs
      assert_test_dbs_dont_exist
      system "script/db_setup -c"
      assert_test_dbs_exist
    end
  end
  
  def test_help
    setup_test_app
    FileUtils.cd FAKE_APP_PATH do
      assert_match /this help screen/, `script/db_setup -h`
    end
  end
  
  def drop_dbs
    db_config.each do |env, config|
      res = `echo 'drop database if exists #{config['database']};' | mysql -u #{config['username']} -p'#{config['password']}'`
    end
  end
  
  def assert_test_dbs_dont_exist
    db_config.each do |env, config|
      res = `echo 'show databases;' | mysql -u #{config['username']} -p'#{config['password']}'`
      assert_no_match /#{config['database']}/, res
    end
  end
  
  def assert_test_dbs_exist
    db_config.each do |env, config|
      res = `echo 'show databases;' | mysql -u #{config['username']} -p'#{config['password']}'`
      assert_match /#{config['database']}/, res
    end
  end
  
  def db_config
    @db_config ||= YAML.load(ERB.new(File.open(FAKE_DB_CONFIG_PATH) {|f| f.read}).result(binding))
  end
  
  def setup_test_app
    FileUtils.cp SCRIPT_PATH, File.join(FAKE_APP_PATH, 'script')
    FileUtils.cp File.join(File.dirname(__FILE__), 'fixtures', 'database.yml'), FAKE_DB_CONFIG_PATH
  end
  
end
