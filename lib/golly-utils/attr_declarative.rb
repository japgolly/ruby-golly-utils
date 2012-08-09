module GollyUtils
  # Creates instance accessors much like `attr_accessor` with the following additional properties:
  #
  # 1. Default values can be specified.
  # 1. Defaults can be overridden in subclasses.
  # 1. Values can be declared, failing-fast on typos.
  #
  # @example
  #   require 'golly-utils/attr_declarative'
  #
  #   class Plugin
  #     attr_declarative :name, :author
  #     attr_declarative required_version: 10
  #   end
  #
  #   class BluePlugin < Plugin
  #     name 'The Blue Plugin'
  #   end
  #
  #   p = BluePlugin.new
  #   puts p.name              # => The Blue Plugin
  #   puts p.author            # => nil
  #   puts p.required_version  # => 10
  #
  # @example Typos fail-fast:
  #   class RedPlugin < Plugin
  #     aauthor 'Homer'        # This will fail to parse
  #
  #     def nnname()           # Alternatively, this wouldn't fail until runtime and even then only if
  #       'The Red Plugin'     # name() was defined in the superclass to fail by default.
  #     end
  #   end
  #
  module AttrDeclarative

    # @!visibility private
    def self.get_default(key, clazz)
      while clazz
        if clazz.instance_variables.include?(key)
          return clazz.instance_variable_get(key)
        end
        clazz= clazz.superclass
      end
      nil
    end

    # Declares one or more attributes.
    #
    # @overload attr_declarative(hash_of_names_to_defaults)
    #   @param [Hash<String|Symbol, Object>] hash_of_names_to_defaults A hash with keys being attribute names, and
    #     values being corresponding default values.
    #
    # @overload attr_declarative(*names, options={})
    #   @param [Array<String|Symbol>] names The attribute names.
    #   @option options [Object] :default (nil) The default value for all specified attributes.
    # @return [nil]
    def attr_declarative(first,*args)
      # Parse args
      names= ([first] + args).flatten.uniq
      options= names.last.is_a?(Hash) ? names.pop.clone : {}

      # Accept <name>: <default> syntax
      if names.empty? and not options.empty?
        options.each do |name,default|
          attr_declarative name, default: default
        end
        return nil
      end

      # Validate options
      default= options.delete :default
      raise "Unknown options: #{options.keys}" unless options.empty?

      # Create attributes
      names.each do |name|
        raise "Invalid attribute name: #{name.inspect}" unless name.is_a?(String) or name.is_a?(Symbol)
        dvar= "@__gu_attr_decl_#{name}_default"
        class_eval <<-EOB

          def #{name}=(value)
            @#{name} = value
          end

          def #{name}
            if instance_variable_defined? :@#{name}
              @#{name}
            elsif d= ::GollyUtils::AttrDeclarative.get_default(:#{dvar}, self.class)
              @#{name}= d
            else
              nil
            end
          end

          def self.#{name}(value)
            instance_variable_set :#{dvar}, value
          end

        EOB
        instance_variable_set dvar.to_sym, default unless default.nil?
      end
      nil
    end

  end
end

Object.extend GollyUtils::AttrDeclarative
