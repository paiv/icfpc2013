
module Icfpc
  class Uri
    attr_accessor :base,  :path, :params, :required

    def initialize(base, path = nil)
      @base = base
      @path = path
      @required = []
    end

    def require(*args)
      @required += args
      return self
    end

    def to_uri
      params = @params || {}
      required = @required || []
      params.delete_if {|k,v| v.nil? || v.to_s.size <= 0 }
      missing = required - params.keys
      raise ArgumentError, "Missing parameters: " + missing.inspect if missing.size > 0

      uri = URI.parse(@base)
      uri.merge!(@path) if @path
      if params.size > 0
        uri.query = format_query(params)
      end
      return uri
    end

    def to_s
      to_uri.to_s
    end

    def format_query(params)
    # TODO: UTF-8 encode keys and values
    # URI.encode_www_form(params)
      params.map {|k,v|
        if v.respond_to?(:to_ary)
          v.to_ary.map {|w|
            k.to_s + '=' + format_value(w)
          }.join('&')
        else
          k.to_s + '=' + format_value(v)
        end
      }.join('&')
    end

    def format_value(v)
      v.is_a?(Time) ? format_time(v) :
        URI.escape(v.to_s)
    end

    def format_time(t)
      t.utc.strftime('%Y-%m-%dT%H:%M:%S')
    end

  end
end

