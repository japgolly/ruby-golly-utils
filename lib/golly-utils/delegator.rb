module GollyUtils

  # An object that delegates method calls to eligible delegate objects.
  class Delegator
    attr_reader :delegate_to

    # @overload initialize(*delegates, options={})
    #   @param [Object] delegates Objects that method calls may be delegated to.
    #   @param [Hash] options
    #   @option options [true,false] :cache (true) Whether or not to maintain a cache of which delegate objects can
    #       respond to each method call.
    #   @option options [:first,:all] :delegate_to (:first) When multiple delegates can respond to a method call, this
    #       setting determines which object(s) are delegated to.
    #   @option options [String, Symbol, Regexp, Array] :method_whitelist Method name matcher(s) that specify which
    #       methods are allowed to be delegated.
    #   @option options [String, Symbol, Regexp, Array] :method_blacklist Method name matcher(s) that specify methods
    #       that are not allowed to be delegated.
    def initialize(*args)
      options= args.last.kind_of?(Hash) ? args.pop.clone : {}
      @original_options= options

      @delegates= args
      @delegate_to= options[:delegate_to] || :first
      @cache= {} unless options.has_key?(:cache) && !options[:cache]
      parse_method_delegation_option options, :method_whitelist
      parse_method_delegation_option options, :method_blacklist
    end

    def dup;   Delegator.new @delegates.map(&:dup),   @original_options end
    def clone; Delegator.new @delegates.map(&:clone), @original_options end

    def method_missing(method, *args)
      matches= delegates_that_respond_to(method)
      return super(method,*args) if matches.empty?

      case delegate_to
      when :first
        matches[0].public_send(method,*args)
      when :all
        matches.map{|m| m.public_send(method,*args)}
      else
        raise "Don't know how to respond to :delegate_to value of #{delegate_to.inspect}"
      end
    end

    def respond_to?(method)
      !delegates_that_respond_to(method).empty?
    end

    private

    def parse_method_delegation_option(options, name)
      if values= options[name]
        methods= [values].flatten.compact.map{|m| m.is_a?(String) ? m.to_sym : m}.uniq
        instance_variable_set :"@#{name}", methods
      end
    end

    def delegates_that_respond_to(method)
      delegation_cache(method){ uncached_delegates_that_respond_to(method) }
    end

    NO_MATCHES= [].freeze
    def uncached_delegates_that_respond_to(method)
      return NO_MATCHES unless @delegates # i.e. not initialised yet, e.g. missing method before super() called in subclass
      return NO_MATCHES if @method_whitelist && !@method_whitelist.any?{|m| m === method}
      return NO_MATCHES if @method_blacklist && @method_blacklist.any?{|m| m === method}
      r= @delegates.select{|d| d.respond_to?(method)}
      r.empty? ? NO_MATCHES : r
    end

    # Don't allow nil values
    def delegation_cache(key)
      if @cache
        @cache[key] ||= yield
      else
        yield
      end
    end
  end
end
