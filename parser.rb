#!/usr/bin/env ruby -I ./ -I ../

require 'parser_icfpc'
require 'gen_lambda'

def parse(prog)
  tt = ProgramRulesParser.new
  c = tt.parse(prog)
  raise '"%s" %s' % [prog, tt.failure_reason] unless c
  c.value
end

def compile(prog)
  e = parse(prog)
  f = gen_lambda(e[0])
  p = [prog,f]
  [p]
end

if __FILE__ == $0

  res = compile('(lambda (x) x)')
  # res = compile('(lambda (x) (plus 1 x))')
  # res = compile('(lambda (x) (or (shl1 x) (plus 1 x)))')
  # res = compile('(lambda (x) (or 1 0))')

  # p res.size
  res.each {|r,f| p r}
end
