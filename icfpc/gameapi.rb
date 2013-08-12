
require 'icfpc/api'
require 'json'

class Integer
  def to_hex
    '0x%016X' % [self]
  end
end

module Icfpc

  module Services
    MY_PROBLEMS = 'myproblems'
    EVAL = 'eval'
    GUESS = 'guess'
    TRAIN = 'train'
    STATUS = 'status'
  end

  class Game < Api
    alias :api_delete :delete

    def list(params = nil)
      uri = uri(Services::MY_PROBLEMS, params)
      return get(uri.to_s)
    end

    def status(params = nil)
      uri = uri(Services::STATUS, params)
      return get(uri.to_s)
    end

    def eval(id, prog, vals, params = nil)
      body = {'arguments' => vals.collect {|x| (x.kind_of?(Integer) ? x : x.to_s.hex).to_hex } }
      body['id'] = id if id
      body['program'] = prog if prog
      uri = uri(Services::EVAL, params)
      res = post_json(uri.to_s, JSON.pretty_generate(body))
      ok = res['status'] == 'ok'
      msg = res['message']
      msg = res.to_s unless msg
      raise msg unless ok
      return res['outputs'].collect {|x| x.hex}
    end
    
    def train(size, ops = nil, params = nil)
      body = {'size' => size }
      body['operators'] = ops if ops
      uri = uri(Services::TRAIN, params)
      return post_json(uri.to_s, JSON.pretty_generate(body))
    end
    
    def guess(pid, prog, params = nil)
      body = {'id' => pid, 'program' => prog }
      uri = uri(Services::GUESS, params)
      return post_json(uri.to_s, JSON.pretty_generate(body))
    end
    
  end

end

