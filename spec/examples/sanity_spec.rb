require File.dirname(__FILE__) + '/../spec_helper'

describe FlexibleApi do

  ActiveRecord::Base.connection.execute 'drop table if exists things'
  ActiveRecord::Base.connection.execute 'create table things (id integer primary key autoincrement, name varchar(255))'

  class Thing < ActiveRecord::Base
    include FlexibleApi
    default_request_level :name_only
    def notation
      'just to note'
    end
  end

  # clean up after our slobby selves
  before :each do 
    Thing.destroy_all
  end

  it 'should be able to serialize an instance at a defined request level' do
    Thing.define_request_level :simple do |level|
      level.fields :id
    end
    thing = Thing.new
    thing.to_hash(:simple).should == { :id => nil }
  end

  it 'should be able to serialize an instance at a RL with multiple fields' do
    Thing.define_request_level :notation do |level|
      level.fields :id, :notation
    end
    thing = Thing.new
    thing.to_hash(:notation).should == { :id => nil, :notation => 'just to note' }
  end

  it 'should be able to call field multiple times with overlapping fields without issue' do
    Thing.define_request_level :separate do |level|
      level.fields :id
      level.fields :id
    end
    thing = Thing.new
    thing.to_hash(:separate).should == { :id => nil }
  end

  it 'should be able to separate calls to fields' do
    Thing.define_request_level :split do |level|
      level.fields :id
      level.fields :notation
    end
    thing = Thing.new
    thing.to_hash(:split).should == { :id => nil, :notation => 'just to note' }
  end

  it 'should be able to make a call to find a note by id at a given request level' do
    Thing.define_request_level :simple2 do |level|
      level.fields :id
    end
    thing = Thing.create
    thing_found = Thing.find_hash(thing.id, :request_level => :simple2)
    thing_found[:id].should == thing.id
  end

  it 'should be able to make a call to find a note by id, and include multiple fields' do
    Thing.define_request_level :wide do |level|
      level.fields :id, :name
      level.fields :notation
    end
    thing = Thing.create(:name => 'john')
    thing_found = Thing.find_hash(thing.id, :request_level => :wide)
    thing_found.should == { :id => thing.id, :name => 'john', :notation => 'just to note' }
  end

  it 'should be able to make a call to find all things at a certain request level' do
    Thing.define_request_level :name_only do |level|
      level.fields :name
    end
    Thing.create(:name => 'apple')
    Thing.create(:name => 'banana')
    Thing.create(:name => 'orange')
    things = Thing.find_all_hash(:request_level => :name_only)
    things.should == [{:name => 'apple'}, {:name => 'banana'}, {:name => 'orange'}]
  end

  it 'should be able to use the deafult request level' do
    thing = Thing.create :name => 'john'
    Thing.find_hash(thing.id).should == { :name => 'john' }
  end

end
