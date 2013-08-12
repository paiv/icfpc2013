#!/usr/bin/env ruby -I ./

require 'gen_lambda'

# $programs = {}

# https://www.ruby-forum.com/topic/95519
def cart_prod( *args )
  args.inject( [[]] ) {|old,lst|
    new = []
    lst.each{|e| new += old.map{|c| c.dup << e }}
    new
  }
end

class CartesianProduct
  include Enumerable
  def initialize(a,b)
    @a = a
    @b = b
  end
  def each       
    @a.each {|a|
    @b.each {|b|
      yield [a,b]
    }}
  end
end
class CartesianProduct3
  include Enumerable
  def initialize(a,b,c)
    @a = a
    @b = b
    @c = c
  end
  def each       
    @a.each {|a|
    @b.each {|b|
    @c.each {|c|
      yield [a,b,c]
    }}}
  end
end

def e_size(e)
  ops = %w| not shl1 shr1 shr4 shr16
            plus and or xor
            if0
            lambda
          |
  ops += [0, 1, 'x']
  
  case e
  when *ops then return 1
  when 'fold' then return 2
  end
  
  e.reduce(0) {|m,x| m + e_size(x)}
end

def xy_sorted(a)
  a.sort_by {|x| x.to_s}
end

def op2_args_matrix(op, args = nil)
  res = $op2matrix[[op,args]] if $op2matrix
  return res if res != nil

  args = ['x',0,1] unless args
  # prod = args.product(args)
  prod = CartesianProduct.new(args, args)
  
  res = case op
  when 'plus'
    prod.collect {|x,y| xy_sorted([x,y])}
  when 'and'
    prod.collect {|x,y| if (x == 0 || y == 0) then [0,0] else xy_sorted([x,y]) end}
  when 'or'
    prod.collect {|x,y| if x == y then [x,x] elsif x == 0 then [0,y] elsif y == 0 then [x,0] else xy_sorted([x,y]) end}
  when 'xor'
    prod.collect {|x,y| if x == y then [x,x] else xy_sorted([x,y]) end}
  else
    raise '! not handled op ' + op
  end

  res &= res
  $op2matrix = {} unless $op2matrix
  $op2matrix[[op,args]] = res
  return res
end

def op3_args_matrix(op, args = nil)
  res = $op3matrix[[op,args]] if $op3matrix
  return res if res != nil

  args = ['x',0,1] unless args
  return args if op == 'fold' # nothing here
  
  # prod = cart_prod(args, args, args)
  prod = CartesianProduct3.new(args, args, args)
  
  res = case op
  when 'if0'
    prod.collect {|x,y,z| if x == 0 then [0,y,0] elsif x == 1 then [1,0,z] else [x,y,z] end}
  when 'tfold'
    prod.collect {|x,y,z| [x,0,z] }
  else
    raise '! not handled op ' + op
  end

  res &= res
  $op3matrix = {} unless $op3matrix
  $op3matrix[[op,args]] = res
  return res
end

def arg_mnemonic2(v)
  names = v.flatten(1)
  names &= names
  n = 0
  r = names.collect {|x| [x,
    case x
    when 0,1,'x','y' then x
    else 'f'.concat((n += 1).to_s)
    end]
  }
  r = Hash[*r.flatten(1)]
  return r.values, v.collect {|a| xy_sorted(a.collect {|x| r[x]}) }
end

def arg_mnemonic3(v)
  names = v.flatten(1)
  names &= names
  n = 0
  r = names.collect {|x| [x,
    case x
    when 0,1,'x','y' then x
    else 'f'.concat((n += 1).to_s)
    end]
  }
  r = Hash[*r.flatten(1)]
  return r.values, v.collect {|a| a.collect {|x| r[x]} }
end

def op_filter2(op, args)
  # p 'args', args
  names, args_mapped = arg_mnemonic2(args)
  # p op, names, args_mapped, '--'
  mx = op2_args_matrix(op, names)
  mx &= args_mapped
  h = Hash[args_mapped.zip(0..args_mapped.size)]
  mx.collect! {|n| args[h[n]] }
end
def op_filter3(op, args)
  names, args_mapped = arg_mnemonic3(args)
  # p op, names, args_mapped, '--'
  mx = op3_args_matrix(op, names)
  mx &= args_mapped
  h = Hash[args_mapped.zip(0..args_mapped.size)]
  mx.collect! {|n| args[h[n]] }
end

def gen_combine1(op, args)
  args.collect {|e| [op, e]}
end
def gen_combine2(op, args)
  args = op_filter2(op, args)
  args.collect {|x,y| [op, x, y]}
end
def gen_combine3(op, args)
  args = op_filter3(op, args)
  args.collect {|x,y,z| [op, x, y, z]}
end

def gen_lambdas_recursive(size, ops, can_fold, addargs=nil)
  # puts '-'*(10-size) + size.to_s
  raise 'gen failed recursion' if size < 1
  if size == 1
    args = ['x', 0, 1]
    args += addargs if addargs
    return args
  end
  
  kk = [size, ops.sort, addargs, can_fold]
  if $programs != nil
    list = $programs[kk]
    return list if list
  end
  list = []
  
  foldos = ops & %w| fold |
  tfoldo = ops & %w| tfold |
  triops = ops & %w| if0 |
  binops = ops & %w| plus and or xor |
  uniops = ops & %w| not shl1 shr1 shr4 shr16 |
  
  if can_fold && size >= 5 && foldos.size > 0
    sz = size - 2
    n = (1..(sz - 2)).to_a
    size_comb = cart_prod(n,n,n).select {|x,y,z| x+y+z == sz}.collect {|x,y,z| [x-1,y-1,z-1]} # adjust for indexes
    args_per_size = n.collect {|x| gen_lambdas_recursive(x, ops, false)} # max 1 fold in a program
    args_per_size_l = n.collect {|x| gen_lambdas_recursive(x, ops, false, ['y'])}
    
    args = size_comb.collect {|x,y,z| [args_per_size[x], args_per_size[y], args_per_size_l[z]] }
    args = args.select {|a,b,c| a != nil && b != nil && c != nil}.collect {|a,b,c| cart_prod(a,b,c)}
    # list += args.collect{|a| gen_combine3('fold', a)}.flatten(1)
    list += foldos.collect {|op| args.collect{|a| gen_combine3(op, a)}.flatten(1) }.flatten(1)
    # p size.to_s + ' *** **', list
  end
  
  if size >= 4 && triops.size > 0
    # p size.to_s + ' *** *'
    sz = size - 1
    n = (1..(sz - 2)).to_a
    size_comb = cart_prod(n,n,n).select {|x,y,z| x+y+z == sz}.collect {|x,y,z| [x-1,y-1,z-1]} # adjust for indexes
    args_per_size = n.collect {|x| gen_lambdas_recursive(x, ops, can_fold, addargs)}
    
    args = size_comb.collect {|x,y,z| [args_per_size[x], args_per_size[y], args_per_size[z]] }
    args = args.select {|a,b,c| a != nil && b != nil && c != nil}.collect {|a,b,c| cart_prod(a,b,c)}
    list += triops.collect {|op| args.collect{|a| gen_combine3(op, a)}.flatten(1) }.flatten(1)
    # list += args.collect{|a| gen_combine3('if0', a)}.flatten(1)
    # p size.to_s + ' *** *', list
  end
  
  if can_fold && size >= 5 && tfoldo.size > 0
    sz = size - 2
    n = (1..(sz - 2)).to_a
    args_per_size = n.collect {|x| gen_lambdas_recursive(x, ops, false)} # max 1 fold in a program
    args_per_size_l = n.collect {|x| gen_lambdas_recursive(x, ops, false, ['y'])}
    args = args_per_size.zip(args_per_size_l.reverse)
    
    args = args.select {|a,b| a != nil && b != nil}.collect {|a,b| cart_prod(a,[0],b) }
    # list += args.collect{|a| gen_combine3('tfold', a)}.flatten(1)
    list += tfoldo.collect {|op| args.collect{|a| gen_combine3(op, a)}.flatten(1) }.flatten(1)
    # p size.to_s + ' *** **', list
  end
  
  if size >= 3 && binops.size > 0
    args = (1..(size - 2)).collect {|x| gen_lambdas_recursive(x, ops, can_fold, addargs)}
    args = args.zip(args.reverse)
    args = args.select {|a,b| a != nil && b != nil}.collect {|a,b| a.product(b) }
    list += binops.collect {|op| args.collect{|a| gen_combine2(op, a)}.flatten(1) }.flatten(1)
    # p size.to_s + ' ***', list
  end

  if size >= 2 && uniops.size > 0
    args = gen_lambdas_recursive(size - 1, ops, can_fold, addargs)
    list += uniops.collect {|op| gen_combine1(op, args) }.flatten(1)
    # p size.to_s + ' **', list
  end

  # p list.size
  # list &= list
  # p list.size
  return nil if list.size == 0
  
  $programs = {} unless $programs
  $programs[kk] = list
  return list
end

def gen_expression(e)
  op = e[0]
  case op
  when 'x','y',0,1
    return op
  when *%w| not shl1 shr1 shr4 shr16 |
    return '(%s %s)' % [op, gen_expression(e[1])]
  when *%w| plus and or xor |
    return '(%s %s %s)' % [op, gen_expression(e[1]), gen_expression(e[2])]
  when *%w| if0 |
    return '(%s %s %s %s)' % [op, gen_expression(e[1]), gen_expression(e[2]), gen_expression(e[3])]
  when *%w| fold tfold |
    return '(fold %s %s (lambda (x y) %s))' % [gen_expression(e[1]), gen_expression(e[2]), gen_expression(e[3])]
  end
  raise '! not handled op ' + op
end

def gen_program(e)
  '(lambda (x) %s)' % [gen_expression(e)]
end

def load_cache(cacheFile)
  res = nil
  if File.exist?(cacheFile) && File.size?(cacheFile)
    File.open(cacheFile, 'rb') {|f|
      begin
        res = Marshal.load(f)
      rescue
        res = {}
      end
    }
  end
  return res
end

def dump_cache(cacheFile, o)
  reuturn unless o
  p 'cache size: ' + o.size.to_s
  if File.exist?(cacheFile)
    File.rename(cacheFile, cacheFile + '.bak')
  end
  File.open(cacheFile, 'wb') {|f|
    Marshal.dump(o, f)
  }
end

def gen_lambdas(size, ops, nocache=false, cacheonly=false)
  p 'gen_lambdas'
  cacheFile = 'gen.cache'
  $programs = load_cache(cacheFile) unless nocache || $programs

  m = nil
  puts Benchmark.measure {
    m = gen_lambdas_recursive(size - 1, ops, true)
  }
  return nil unless m
  
  dump_cache(cacheFile, $programs) unless nocache
  return if cacheonly

  m.select! {|e|
    a = e.flatten
    (ops & a) == ops &&
      (a.count('fold') + a.count('tfold')) <= 1 # max 1 fold in a program
  }
  
  p 'emit...'
  res = nil
  puts Benchmark.measure {
    res = m.collect {|e| [gen_program(e), gen_lambda(e)] }
  }
  return res
end


if __FILE__ == $0

  # p gen_lambdas_recursive(3, ['plus'], false, ['y'])
  # res = gen_lambdas(9, ['tfold', 'plus', 'shl1'], true)

  # p res.size
  # res.each {|r,f| p r}
end
