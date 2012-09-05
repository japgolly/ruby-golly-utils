module GollyUtils
  # Creates instance accessors much like `attr_accessor` with the following additional properties:
  #
  # 1. Default values can be specified.
  # 1. Defaults can be overridden in subclasses.
  # 1. Values can be declared, failing-fast on typos.
  # 1. Explicit declaration of an attribute value can be required and enforced. (Optional)
  #
  #    i.e. if an attribute is read before a value has been specified, then an error will be thrown.
  #
  # Attributes ending in `?` or `!` will have said suffix removed in the instance variable, and writer method names.
  #
  # @example
  #   require 'golly-utils/attr_declarative'
  #
  #   class Plugin
  #     attr_declarative :name, :author
  #     attr_declarative version: 10
  #   end
  #
  #   class BluePlugin < Plugin
  #     name 'The Blue Plugin'
  #   end
  #
  #   p = BluePlugin.new
  #   puts p.name              # => The Blue Plugin
  #   puts p.author            # => nil
  #   puts p.version           # => 10
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
  # @example Attribute value declaration can be required and enfored:
  #   class Plugin
  #     attr_declarative :name, required: true
  #   end
  #
  #   class BluePlugin < Plugin
  #   end
  #
  #   p = BluePlugin.new
  #   puts p.name        # => RuntimeError: Attribute 'name' required by Plugin but not set in BluePlugin.
  #
  # @example Attibutes with special naming rules
  #   class SpecialNames
  #     attr_declarative :happy?
  #     attr_declarative :my_fist!
  #
  #     happy?   false               # Class-level declaration includes suffix
  #     my_fist! :its_amazing        # Class-level declaration includes suffix
  #   end
  #
  #   puts SpecialNames.new.happy?   # Instance method includes suffix
  #   puts SpecialNames.new.my_fist! # Instance method includes suffix
  #
  #   SpecialNames.new.happy= false  # Instance-level declaration replaces suffix with =
  #   SpecialNames.new.my_fist= nil  # Instance-level declaration replaces suffix with =
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
    #   @option options [Object] :required (false) If required, an attribute will raise an error if it is read before it
    #     has been set.
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
      required= (options.has_key? :required) ? options.delete(:required): false
      raise "Unknown options: #{options.keys}" unless options.empty?

      # Create attributes
      names.each do |name|
        raise "Invalid attribute name: #{name.inspect}" unless name.is_a?(String) or name.is_a?(Symbol)
        safe_name= name.to_s.sub /[!?]$/, ''
        dvar= "@__gu_attr_decl_#{safe_name}_default"
        ivar= "@#{safe_name}"
        meth_w= "#{safe_name}="
        meth_r= name

        class_eval <<-EOB

          def #{meth_w}(value)
            #{ivar} = value
          end

          def #{meth_r}
            if instance_variable_defined? :#{ivar}
              #{ivar}
            elsif d= ::GollyUtils::AttrDeclarative.get_default(:#{dvar}, self.class)
              #{ivar}= d
            else
              #{required ? %[raise "Attribute '#{name}' required by #{self} but not set in #\{self.class}."] : 'nil'}
            end
          end

          def self.#{meth_r}(value)
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
