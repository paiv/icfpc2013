#!/usr/bin/env ruby -I ./ -I ../

require 'rubygems'
require 'parser'
require 'json'

prog = ARGV[0]

if not ARGV[1] then
  puts "usage: myeval <program> <integers ...>"
  exit(0)
end

vals = ARGV[1..ARGV.size].collect{|x| x.hex}

ans = compile(prog)
p f = ans[0][1]
res = vals.collect{|x| f[x]}
res.collect! {|x| '0x%016X' % [x] }
puts JSON.pretty_generate(res)
