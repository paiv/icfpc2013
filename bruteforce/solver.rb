#!/usr/bin/env ruby -I ./ -I ../

require 'rubygems'
require 'paiv'
require 'json'
require 'gen'
require 'benchmark'

SOLVER_SIZE = 10

def pp_json(o)
  JSON.pretty_generate(o)
end

def the_one(tests, ans)
  m = ans.collect {|p,f| tests.collect{|v| v.collect{|x| f[x]} }}
  u = m & m # remove equivalent lambdas
  # idx = u.collect {|v| m.find_index{|x| x == v} }
  
  i = u.transpose.find_index {|x|
    (x & x) == x
  }
  return tests[i] if i
end

def reduce(ans, fix_disc = nil)
  game = GAME
  
  # disc = [1,2]
  disc = [0,1,2, 0xB5DE59E6FB205E6B, 0x4A21A61904DFA194]
  # disc = [0,1,2,3, 0xB5DE59E6FB205E6B, 0x4A21A61904DFA194, 0x0000000000010000, 0x7FFFFFFFFFFFFFFE]
  disc += fix_disc if fix_disc
  disc &= disc
  # p 'disc', disc, '---'
  # combs = disc.product(disc)
  combs = cart_prod(disc, disc, disc)

  ask = the_one(combs, ans)
  # raise '! no fate' unless ask
  if not ask
    puts '! no fate'
    ask = combs.first
    ask += fix_disc if fix_disc
    ask &= ask
  end
  return ask
end

def eval(pid, challenge, ans, ask)
  game = GAME
  puts ('eval "%s" %s' % [pid, ask])
  puts 'challenge: ' + challenge if challenge
  b = game.eval(pid, challenge, ask)
  puts b
  m = ans.collect {|_,f| ask.collect {|x| f.call(x)} }

  k = m.find_index(b)

  if not k
    puts '! optimized out; using blind guess'
    k = rand(ans.size)
  end
    
  return ans[k].first
end

def submit(pid, p)
  game = GAME
  puts 'guess: ', p
  return nil unless pid
  
  res = game.guess(pid, p)
  status = res['status']
  if status == 'win' then
    puts '+ accepted'
    File.open('accepted.txt','a+') {|f| f.puts(pid)}
    return
  elsif status == 'mismatch' then
    puts pp_json(res)
    # raise status
    return res['values'][0].hex
  else
    puts pp_json(res)
  end
  return nil
end

def pre_cache(prob)
  pid = prob['id']
  size = prob['size'].to_i
  ops = prob['operators']
  chal = prob['challenge']

  puts ('pre cache "%s"' % [pid])
  puts 'challenge: ' + chal if chal
  generate(size, ops, false, true)
end

def generate(size, ops, nocache=false, cacheonly=false)
  gen_lambdas(size, ops, nocache, cacheonly)
end

def solve(prob, fix_disc = nil, nocache=false)
  pid = prob['id']
  size = prob['size'].to_i
  ops = prob['operators']
  chal = prob['challenge']

  raise('! size %d or less only' % [SOLVER_SIZE]) if size > SOLVER_SIZE
  p 'gen...'
  ans = generate(size, ops, nocache)
  # ans.each{|p,_| puts p}
  # puts '--'
  
  mismatch = false
  begin
    # p 'fix_disc', fix_disc, '--'
    p 'reduce...'
    check = nil
    puts Benchmark.measure {
      check = reduce(ans, fix_disc)
    }
    ans2 = eval(pid, chal, ans, check)
    r = submit(pid, ans2)
    if r != nil
      fix_disc = [] unless fix_disc
      fix_disc << r
      mismatch = true
      sleep(2)
    else
      mismatch = false
    end
  end while mismatch
end


if __FILE__ == $0

  args = %w| --no-cache --pre-cache-only |

  no_cache = ARGV.include?('--no-cache')
  pre_cache = ARGV.include?('--pre-cache-only')
  ARGV.select! {|a| not args.include?(a) }
  raise '! unexpected params' if ARGV.join().include?('-')
  
  data = ARGF.read

  if not data then
    puts "usage: solver <problem json>] " + args.join(' ')
    exit(0)
  end

  probs = JSON.parse(data)
  probs = [probs] unless probs.is_a?(Array)
  probs.each {|p| pre_cache ? pre_cache(p) : solve(p, nil, no_cache) }

end
