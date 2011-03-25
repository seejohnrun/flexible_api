require File.dirname(__FILE__) + '/../spec_helper'

describe FlexibleApi do
  
  ActiveRecord::Base.connection.execute 'drop table if exists people'
  ActiveRecord::Base.connection.execute 'drop table if exists houses'
  ActiveRecord::Base.connection.execute 'create table people (id integer primary key autoincrement, name varchar(255))'
  ActiveRecord::Base.connection.execute 'create table houses (id integer primary key autoincrement, person_id integer)'

  class House < ActiveRecord::Base
    include FlexibleApi
    belongs_to :person
  end

  class Person < ActiveRecord::Base
    include FlexibleApi
    has_many :houses
  end

  it 'should be able to use a include in a request level' do
    House.define_request_level :simple do |level|
      level.fields :id
    end
    Person.define_request_level :with_houses do |level|
      level.fields :name
      level.requires :id
      level.includes :houses, :request_level => :simple
    end

    ['john', 'kate'].each do |name|
      person = Person.create(:name => name)
      5.times { person.houses.create }
    end

    data = Person.find_all_hash(:request_level => :with_houses)
    data.map { |e| e[:name] }.should == ['john', 'kate']
    data.each { |e| e[:houses].length.should == 5 }
  end 

  it 'should be able to use an include with a different name' do
    person = Person.create
    Person.define_request_level :include_naming do
      includes :houses, :as => :the_houses
    end
    person.to_hash(:include_naming).should == { :the_houses => [] }
  end

end
