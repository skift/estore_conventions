$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))


require 'rspec'
require 'mysql2'
require 'active_record'
require 'database_cleaner'
require 'pry'

require 'estore_conventions'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :database => "test_estore_conventions",
  username: 'root',
  password: ''
)

ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :music_records , force: true do |t|
    t.string     "t_id"
    t.string     "title"
    t.string     "genre"
    t.datetime   'published_at'
    t.integer    'quantity'
    t.float      'price'
    t.string      'description'
  end 
end

class MusicRecord < ActiveRecord::Base 
  include EstoreConventions
  attr_datetime :published_at
end

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
