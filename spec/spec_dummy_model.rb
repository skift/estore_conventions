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
    t.datetime 'rails_updated_at'
    t.datetime 'rails_created_at'
  end 

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

end

class MusicRecord < ActiveRecord::Base 
  include EstoreConventions
  has_paper_trail 
  attr_datetime :published_at
end