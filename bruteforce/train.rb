#!/usr/bin/env ruby -I ./ -I ../

require 'rubygems'
require 'json'
require 'solver'

args = %w| --no-folds --no-cache |

no_cache = ARGV.include?('--no-cache')
no_folds = ARGV.include?('--no-folds')
ARGV.select! {|a| not args.include?(a) }
raise '! unexpected params' if ARGV.join().include?('-')

size = ARGV[0]
ops = ARGV[1]

if not size then
  puts "usage: train n [ops] " + args.join(' ')
  exit(0)
end

game = GAME
ops = ops ? [ops] : []


repeat = false
begin
  begin
    
    begin
      prob = game.train(size.to_i, ops)
      prob_ops = prob['operators']
      puts '%d %s %s' % [ prob['size'], prob['id'], prob_ops.join(' ')]

      if no_folds
        if prob_ops.include?('fold') || prob_ops.include?('tfold')
          puts 'ignoring folds'
          next
        end
      end
        
      File.open('train_dump.json', 'w') {|f|
        f.write( JSON.pretty_generate(prob) )
      }
      sleep(0.6)
      
      solve(prob, nil, no_cache)
      
      sleep(3)
    end while true
    
  rescue Icfpc::IcfpcError => e
    puts e
    repeat = e.code == 429 # too many requests
  end
  sleep(1)
end while repeat
