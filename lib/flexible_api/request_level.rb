module FlexibleApi

  class RequestLevel

    def initialize(name, klass)
      @name = name
      @klass = klass
      @display_fields = Set.new
      @select_fields = Set.new
      @scopes = []
      @includes = []
      @notations = {}
      @eaten_levels = []
      @select_fields << "`#{@klass.table_name}`.#{@klass.primary_key}" # auto-select primary key
    end

    attr_reader :display_fields, :name, :notations

    def to_hash
      {
        :name => @name,
        :fields => display_field + notations.keys,
        :includes => @includes.map do |inc|
          { :name => inc[:name], :type => inc[:association].name.to_s.pluralize.underscore.downcase, :request_level => inc[:request_level].name }
        end
      }
    end

    def eat_level(name)
      @eaten_levels << @klass.find_level(name)
    end

    def scope(name, args = nil)
      @scopes << [name, args]
    end

    def notation(notation_name, options = {}, &block)
      options.assert_valid_keys :requires
      requires *options[:requires]
      @notations[notation_name] = block
    end
    
    def method(method_name, options = {})
      options.assert_valid_keys :request_level, :as, :requires
      method = @klass.instance_methods.detect { |m| m == method_name.to_sym }
      raise "No such method on #{@klass.name}: #{method_name}" if method.nil?
      notation_options = (options.has_key?(:requires) ? {:requires => options[:requires]} : {})
      notation(options[:as] || method_name, notation_options) do
        method_contents = self.send(method_name)
        if method_contents.is_a?(Array)
          method_contents.map {|content| content.to_hash(options[:request_level]) }
        else
          method_contents.to_hash(options[:request_level])
        end        
      end    
    end

    def includes(association_name, options = {})
      options.assert_valid_keys :request_level, :as, :requires
      association = @klass.reflect_on_all_associations.detect { |a| a.name == association_name.to_sym }
      raise "No such association on #{@klass.name}: #{association_name}" if association.nil? # TODO
      # Allow requires to pass in
      requires *options[:requires] if options.has_key?(:requires)
      # Set the include options
      @includes << { 
        :name => options[:as] || association_name,
        :association => association, 
        :request_level => association.klass.find_level(options[:request_level])
      }
    end

    def requires(*requires_array)
      requires_array.each do |field|
        if field.is_a?(String)
          @select_fields << field
        else
          @select_fields << "`#{@klass.table_name}`.#{field}" if @klass.columns_hash.keys.include?(field.to_s)
        end
      end
    end

    def all_fields
      fields *@klass.columns_hash.keys.map(&:to_sym)
    end

    def fields(*field_array)
      field_array.each do |field|
        if field.is_a?(String)
          @display_fields << field.split('.').last.to_sym
          @select_fields << field
        else
          @display_fields << field
          @select_fields << "`#{@klass.table_name}`.#{field}" if @klass.columns_hash.keys.include?(field.to_s)
        end
      end
    end

    #################################################

    def scope_field
      @scopes_array ||= begin
        scopes = []
        scopes.concat @scopes
        @eaten_levels.each { |l| scopes.concat l.scope_field }
        scopes
      end
    end

    def select_field
      @select_field_array ||= begin
        selects = @select_fields.to_a
        @eaten_levels.each { |l| selects.concat l.select_field }
        selects
      end
    end

    def display_field
      @display_field_array ||= begin
        displays = @display_fields.to_a
        @eaten_levels.each { |l| displays.concat l.display_field }
        displays
      end
    end

    def include_field
      @include_field_array ||= begin
        includes = @includes.map { |i| i[:association].name }
        @eaten_levels.each { |l| includes.concat l.include_field }
        includes
      end
    end

    def receive(item)
      return nil if item.nil? # method may be nil
      attributes = {}
      @eaten_levels.each do |level|
        attributes.merge! level.receive(item)
      end
      @display_fields.each do |field|
        attributes[field] = item.send(field)
      end
      @includes.each do |include|
        value = item.send(include[:association].name)
        value = value.is_a?(Enumerable) ? value.map { |e| include[:request_level].receive(e) } : include[:request_level].receive(value)
        attributes[include[:name]] = value
      end
      @notations.each do |name, block|
        attributes[name] = item.instance_eval(&block)
      end
      attributes
    end

  end

end
