#!/usr/bin/env ruby -I ./

require 'json'

args = %w| --count --no-folds --solved --failed --no-fresh --all --bonus |

count_only = ARGV.include?('--count')
no_folds = ARGV.include?('--no-folds')
no_solved = ! ARGV.include?('--solved')
no_failed = ! ARGV.include?('--failed')
no_fresh = ARGV.include?('--no-fresh')
no_bonus = ! ARGV.include?('--bonus')
if ARGV.include?('--all') then no_solved = no_failed = no_fresh = false end
ARGV.select! {|a| not args.include?(a) }
raise '! unexpected params' if ARGV.join().include?('-')

size = ARGV[0]
ops = ARGV[1..ARGV.size]

if not size then
  puts "usage: select n " + args.join(' ')
  exit(0)
end
size = size.to_i

solved = File.read('accepted.txt').split if File.exist?('accepted.txt')
solved = [] unless solved

probs = JSON.parse( File.read('myproblems.json') )
probs.select! {|p|
  (size == 0 or p['size'] == size)
}

if no_fresh then
  probs.select! {|p| (p['solved'] != nil || solved.include?(p['id'])) }
end
if no_solved then
  probs.select! {|p| not (p['solved'] == true || solved.include?(p['id'])) }
end
if no_failed then
  probs.select! {|p| not (p['solved'] == false)}
end

if no_folds
  folds = %w| fold tfold |
  probs.select! {|p| not folds.any? {|x| p['operators'].include?(x)} }
end
if no_bonus then
  probs.select! {|p| not p['operators'].include?('bonus') }
end

if ops && ops.size > 0
  # probs.select! {|p| ops.all? {|x| p['operators'].include?(x)} }
  probs.select! {|p| 
    p['operators'].sort == ops.sort
  }
end

if count_only then
  puts probs.size
else
  puts JSON.pretty_generate(probs)
end
