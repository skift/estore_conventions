$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))


require 'rspec'
require 'mysql2'
require 'active_record'
require 'database_cleaner'
require 'pry'
require 'timecop'

require 'estore_conventions'
require 'spec_dummy_model'



DatabaseCleaner.strategy = :truncation



RSpec.configure do |config|
  config.filter_run_excluding skip: true 
  config.run_all_when_everything_filtered = true
  config.filter_run :focus => true

  config.color_enabled = true
  config.tty = true
  config.formatter = :documentation # :progress, :html, :textmate

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
