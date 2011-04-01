require File.dirname(__FILE__) + '/../spec_helper'

describe FlexibleApi do

  ActiveRecord::Base.connection.execute 'drop table if exists cups'
  ActiveRecord::Base.connection.execute 'create table cups (id integer primary key autoincrement, name varchar(255))'

  class Cup < ActiveRecord::Base
    include FlexibleApi
    scope :starts_with, lambda { |a| where('name LIKE ?', "#{a}%") }
    scope :starts_with_a, where('name LIKE ?', 'a%')
  end

  # clean up after our slobby selves
  before :each do 
    Cup.destroy_all
  end

  it 'should be able to define a request level with a scope that takes arguments' do
    Cup.create :name => 'john'
    Cup.create :name => 'apple'
    # define a request level
    Cup.define_request_level :scoped do
      scope :starts_with, 'a'
      all_fields
    end
    # Find at scoped level
    cups = Cup.find_all_hash(:request_level => :scoped)
    cups.size.should == 1
    # Find at unscoped level
    cups = Cup.find_all_hash
    cups.size.should == 2
  end

  it 'should be able to define a request level with a scope that does not take arguments' do
    Cup.create :name => 'john'
    Cup.create :name => 'apple'
    # define a request level
    Cup.define_request_level :scoped do
      scope :starts_with_a
      all_fields
    end
    # Find at scoped level
    cups = Cup.find_all_hash(:request_level => :scoped)
    cups.size.should == 1
    # Find at unscoped level
    cups = Cup.find_all_hash
    cups.size.should == 2
  end

  it 'should be able to eat a level with a scope' do
    Cup.create :name => 'john'
    Cup.create :name => 'apple'

    Cup.define_request_level :eats_scoped do
      eat_level :scoped
    end

    cups = Cup.find_all_hash(:request_level => :eats_scoped)
    cups.size.should == 1
  end

end
