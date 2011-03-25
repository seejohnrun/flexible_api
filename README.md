# FlexibleAPI

FlexibleAPI is a way to quickly build APIs inside of ActiveRecord models.

    class Thing < ActiveRecord::Base

      define_request_level :simple do |level|
        level.fields :id, :name, :reverse_name
      end

      def reverse_name
        name.reverse
      end

    end

That gives you the ability to do:

    Thing.first.to_hash :simple # { :id => 1, :name => 'john', :reverse_name => 'nhoj' }

And if you use something like:

    Thing.find_hash(:request_level => :simple)

Which will preselect only the fields that it needs, and if you do:

    Thing.find_all_hash(:request_level => :simple)

It will preselect everything it needs to do those queries efficiently.

---

## Nesting

    define_request_level :complex do |level|
      level.fields :id, :name
      level.includes :association
    end

---

## FlexibleAPIServer

This is a way to expose FlexibleAPIs via a thin Sinatra server, which makes restful paths for all of the request levels that you create

---

### License

MIT License.  See attached
