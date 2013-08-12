
require 'rest-client'
require 'multi_json'
require 'icfpc/uri'

module Icfpc

  module Endpoints
    V1 = 'http://icfpc2013.cloudapp.net/'
    CURRENT = V1
  end
  
  class IcfpcError < Exception
    attr_reader :code
    def initialize(res)
      super('%i %s' % [res.code, res.to_s])
      @code = res.code
    end
  end

  class Api
    attr_accessor :apiKey, :projectId, :baseUrl

    def initialize(args = {})
      @apiKey = args[:apiKey]
      @baseUrl = args[:baseUrl] || Endpoints::CURRENT
    end

    def uri(path, params1 = nil, params2 = nil)
      uri = Uri.new(@baseUrl, path)
      params = { :auth => @apiKey }
      params.merge!(params1) if params1
      params.merge!(params2) if params2
      uri.params = params
      uri.require(:auth)
      return uri
    end

    def check_response(res)
      return if res.code == 200
      return if res.code == 412
      # raise format_api_error(res.body)
      raise IcfpcError, res
    end

    def process(res)
      check_response(res)
      return res if res.code == 412 # already solved
      body = MultiJson.decode(res.body)
      return body
    end

    def format_api_error(res)
      begin
        body = MultiJson.decode(res.body)
      rescue
      end
      return (body or res)
    end

    def get(uri)
      RestClient.get(uri) {|res, _, _|
        process(res)
      }
    end
    def get_raw(uri)
      RestClient.get(uri) {|res, _, _|
        check_response(res)
        res.body
      }
    end
    def post(uri, params = nil)
      RestClient.post(uri, params) {|res, _, _|
        process(res)
      }
    end
    
    def post_json(uri, json, params = nil)
      repeat = false
      begin
        sleep(1) if repeat
        return RestClient.post(uri, json, :content_type => :json) {|res, _, _|
          process(res)
        }
      rescue IcfpcError => ex
        repeat = ex.code == 429 # too many requests
        raise unless repeat
      end while repeat
    end

    def delete(uri)
      RestClient.delete(uri) {|res, _, _|
        process(res)
      }
    end

    def log=(v)
      RestClient.log = v
    end
    def proxy=(v)
      RestClient.proxy = v
    end
  end

end

