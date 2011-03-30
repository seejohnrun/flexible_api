module FlexibleApi

  autoload :RequestLevel, File.dirname(__FILE__) + '/flexible_api/request_level'
  autoload :NoSuchRequestLevelError, File.dirname(__FILE__) + '/flexible_api/no_such_request_level_error'

  @@flexible_models = []

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    @@flexible_models << base
  end

  def self.flexible_models
    @@flexible_models
  end

  module ClassMethods

    def request_levels
      @levels.nil? ? [] : @levels.keys
    end

    # Define a request level for this class
    # Takes a name, and a block which defined the request level
    def define_request_level(name, &block)
      level = RequestLevel.new(name, self)
      level.instance_eval &block
      @levels ||= {}
      @levels[name] = level
    end

    # Find a single element and load it at the given request level
    def find_hash(id, options = {})
      options.assert_valid_keys(:request_level)
      level = find_level(options[:request_level])
      record = self.find(id, :select => level.select_field.join(', '), :include => level.include_field)
      level.receive record
    end

    # Find all of an element (or association) and load it at the given request level
    def find_all_hash(options = {})
      options.assert_valid_keys(:request_level)
      level = find_level(options[:request_level])

      query = self
      level.scopes.each do |s, args|
        query = args.nil? ? query.send(s) : query = query.send(s, *args)
      end

      records = query.all(:select => level.select_field.join(', '), :include => level.include_field)
      records.map { |r| level.receive(r) }
    end

    def default_request_level(level_name)
      @default_request_level_name = level_name
    end

    # Find a given level by name and return the request level
    def find_level(name = nil)
      @levels ||= {}
      level = name.nil? ? load_default_request_level : @levels[name.to_sym]
      raise NoSuchRequestLevelError.new(name, self.name) if level.nil?
      level
    end

    private

    def load_default_request_level
      @default_request_level ||= 
        if @default_request_level_name.nil?
          level = RequestLevel.new(:default, self)
          level.all_fields
          level
        else
          self.find_level(@default_request_level_name)
        end
    end

  end

  module InstanceMethods

    # Return a hash of this element at the given request level (by name)
    def to_hash(level_name)
      level = self.class.find_level level_name
      level.receive self
    end

  end

end
