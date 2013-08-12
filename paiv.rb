#!/usr/bin/env ruby -I ./

require 'rubygems'
require 'icfpc'

API_KEY = File.read('apikey.txt')

game = Icfpc::Game.new(:apiKey => API_KEY + 'vpsH1H')
game.log = 'game.log'

GAME = game

def dump_mybroblems(game)
  a = game.list()
  a.sort! {|x,y| x['size'] <=> y['size']}
  s = JSON.pretty_generate(a)
  File.open('myproblems_.json', 'w') {|f| f.write(s)}
end


if __FILE__ == $0

  args = %w| stats dump |
  
  do_stats = ARGV.include?('stats')
  do_dump = ARGV.include?('dump')
  ARGV.select! {|a| not args.include?(a) }
  raise '! unexpected params' if ARGV.join().include?('-')
  
  nothing = ! (do_stats || do_dump)
  
  if nothing then
    puts "usage: paiv " + args.join(' ')
    exit(0)
  end
  
  puts 'paiv client ' + Icfpc::VERSION
  
  dump_mybroblems(game) if do_dump
  puts game.status() if do_stats

# res = game.list()
# res = game.train(30, ['tfold'])

end