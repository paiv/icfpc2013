#!/usr/bin/env ruby -I ./

require 'rubygems'
require 'icfpc'
require 'paiv'

args = %w| --program |

is_program = ARGV.include?('--program') || ARGV[0].include?('(lambda')
ARGV.select! {|a| not args.include?(a) }

id = ARGV[0] if not is_program
prog = ARGV[0] if is_program

if not ARGV[1] then
  puts "usage: eval [" + args.join(' ') + "] <id|program> <integers ...>"
  exit(0)
end

game = GAME
vals = ARGV[1..ARGV.size]

res = game.eval(id, prog, vals)
res.collect! {|x| '0x%016X' % [x] }
puts JSON.pretty_generate(res)
