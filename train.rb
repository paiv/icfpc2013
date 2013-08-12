#!/usr/bin/env ruby -I ./

require 'rubygems'
require 'icfpc'
require 'paiv'

size = ARGV[0]
ops = ARGV[1]

if not size then
  print "usage: train n [ops]\n"
  exit(0)
end

game = GAME
ops = [ops] if ops

res = game.train(size.to_i, ops)
puts JSON.pretty_generate(res)
