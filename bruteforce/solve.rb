#!/usr/bin/env ruby -I ./ -I ../

require 'rubygems'
require 'json'
require 'solver'

accepted_list = File.readable?('accepted.txt') ? File.read('accepted.txt').split : []

probs = JSON.parse( ARGF.read )
probs.each {|p|
  solved = accepted_list.include?(p['id']) || p['solved'] != nil
  next if solved
  
  solve(p)
  sleep(2)
}
