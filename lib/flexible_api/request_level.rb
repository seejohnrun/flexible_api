module FlexibleApi

  class RequestLevel

    def initialize(name, klass)
      @name = name
      @klass = klass
      @display_fields = Set.new
      @select_fields = Set.new
      @includes = []
      @notations = {}
      @eaten_levels = []
    end

    attr_reader :display_fields, :name, :notations

    def to_hash
      {
        :name => @name,
        :fields => select_field + notations.keys,
        :includes => @includes.map do |inc|
          { :name => inc[:name], :type => inc[:association].name.to_s.pluralize.underscore.downcase, :request_level => inc[:request_level].name }
        end
      }
    end

    def eat_level(name)
      @eaten_levels << @klass.find_level(name)
    end

    def notation(notation_name, options = {}, &block)
      options.assert_valid_keys :requires
      requires *options[:requires]
      @notations[notation_name] = block
    end

    def includes(association_name, options = {})
      options.assert_valid_keys :request_level, :as
      association = @klass.reflect_on_all_associations.detect { |a| a.name == association_name.to_sym }
      raise "No such association on #{@klass.name}: #{association_name}" if association.nil? # TODO
      @includes << { 
        :name => options[:as] || association_name,
        :association => association, 
        :request_level => association.klass.find_level(options[:request_level])
      }
    end

    def requires(*requires_array)
      requires_array.each do |field|
        @select_fields << "`#{@klass.table_name}`.#{field}"
      end
    end

    def all_fields
      fields *@klass.columns_hash.keys
    end

    def fields(*field_array)
      field_array.each do |field|
        @display_fields << field
        @select_fields << "`#{@klass.table_name}`.#{field}" if @klass.columns_hash.keys.include?(field.to_s)
      end
    end

    #################################################

    def select_field
      @select_field_array ||= begin
        selects = @select_fields.to_a
        @eaten_levels.each { |l| selects.concat l.select_field }
        selects
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
