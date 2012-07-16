module GollyUtils
  module AttrDeclarative

    def self.included(base)
      base.send :include, InstanceMethods
      base.send :include, InstanceAndClassMethods
      base.extend InstanceAndClassMethods
      base.extend ClassMethods
    end

    private

    def self.get_default(key, clazz)
      while clazz
        if clazz.instance_variables.include?(key)
          return clazz.instance_variable_get(key)
        end
        clazz= clazz.superclass
      end
      nil
    end

    #-------------------------------------------------------------------------------------------------------------------

    # TODO default should be default_value/default_proc
    # TODO add an option to specify whether proc should be eval'd everytime or once and return value cached

    module ClassMethods
      def attr_declarative(first,*args)
        names= ([first] + args).flatten.uniq
        options= names.last.is_a?(Hash) ? names.pop.clone : {}
        default= options.delete :default
        raise "Unknown options: #{options.keys}" unless options.empty?
        names.each do |name|
          dvar= "@_#{name}_default"
          class_eval <<-EOB

            def #{name}
              if block_given?
                @#{name}= yield
              elsif not @#{name}.nil?
                @#{name}
              elsif d= ::GollyUtils::AttrDeclarative.get_default(:#{dvar}, self.class)
                @#{name}= d.call
              else
                nil
              end
            end

            def self.#{name}(&block)
              instance_variable_set :#{dvar}, block
            end

          EOB
          instance_variable_set dvar.to_sym, lambda{ default } unless default.nil?
        end


            #{default.nil? ? '' : "instance_variable_set :#{dvar}, block
                #{default.nil? ? 'nil' : "@#{name}= (#{default.inspect})"}
      end
    end

    #-------------------------------------------------------------------------------------------------------------------

    module InstanceAndClassMethods
    end

    #-------------------------------------------------------------------------------------------------------------------

    module InstanceMethods
    end
  end
end
