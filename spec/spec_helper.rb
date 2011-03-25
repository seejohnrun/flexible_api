require 'bundler/setup'
require 'active_record'

ActiveRecord::Base.establish_connection(:database => 'spec/test.db', :adapter => 'sqlite3')

# require 'logger'
# ActiveRecord::Base.logger = Logger.new(STDOUT)

require File.dirname(__FILE__) + '/../lib/flexible_api'
