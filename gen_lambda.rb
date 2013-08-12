#!/usr/bin/env ruby

require 'benchmark'

# def op_lambda2(f,x,y)
#   tpl = 'lambda{|x| f[%s, %s]}'
#   eval(tpl % [x,y])
# end

def op_lambda(op)
  mask64 = 0xFFFFFFFFFFFFFFFF
  mask8 = 0xFF
  case op
  when 'not'
    return lambda {|x| (~x) & mask64}
  when 'shl1'
    return lambda {|x| (x << 1) & mask64}
  when 'shr1'
    return lambda {|x| (x >> 1) & mask64}
  when 'shr4'
    return lambda {|x| (x >> 4) & mask64}
  when 'shr16'
    return lambda {|x| (x >> 16) & mask64}
  when 'plus'
    return lambda {|x,y| (x + y) & mask64}
  when 'and'
    return lambda {|x,y| (x & y) & mask64}
  when 'or'
    return lambda {|x,y| (x | y) & mask64}
  when 'xor'
    return lambda {|x,y| (x ^ y) & mask64}
  when 'if0'
    return lambda {|x,y,z| x == 0 ? y : z}
  when 'fold', 'tfold'
    return lambda {|x,y,z| 
      z[(x >> 56) & mask8,
      z[(x >> 48) & mask8,
      z[(x >> 40) & mask8,
      z[(x >> 32) & mask8,
      z[(x >> 24) & mask8,
      z[(x >> 16) & mask8,
      z[(x >> 8) & mask8,
      z[(x & mask8), y]]]]]]]]
    }
  end
  raise '! not handled op ' + op
end

def gen_lambda1(e)
  op = e[0]
  case op
    
  when 'x'
    lambda {|x| x }
  when 0
    lambda {|x| 0 }
  when 1
    lambda {|x| 1 }
    
  when *%w| not shl1 shr1 shr4 shr16 |
    a = gen_lambda(e[1])
    lambda {|x| op_lambda(op)[ a[x] ]}
    
  when *%w| plus and or xor |
    a = gen_lambda(e[1])
    b = gen_lambda(e[2])
    lambda {|x| op_lambda(op)[ a[x], b[x] ]}

  when *%w| if0 fold tfold |
    a = gen_lambda(e[1])
    b = gen_lambda(e[2])
    c = gen_lambda(e[3])
    lambda {|x| op_lambda(op)[ a[x], b[x], c[x] ]}

  else
    raise '! not handled op ' + op
  end
end

def gen_lambda2_shift(op)
  case op
  when 'shl1'  then '((%s << 1) & mask64)'
  when 'shr1'  then '((%s >> 1) & mask64)'
  when 'shr4'  then '((%s >> 4) & mask64)'
  when 'shr16' then '((%s >> 16) & mask64)'
  end
end
def gen_lambda2_binary(op)
  case op
  when 'plus'  then '((%s + %s) & mask64)'
  when 'and'  then '((%s & %s) & mask64)'
  when 'or'  then '((%s | %s) & mask64)'
  when 'xor'  then '((%s ^ %s) & mask64)'
  end
end

def gen_lambda2(e)
  op = e[0]

  case op
  when 'x','y', 0, 1
    return op.to_s
  end

  raise '! array expected' unless e.is_a?(Array)
  a = gen_lambda2(e[1]) if e.size > 1
  b = gen_lambda2(e[2]) if e.size > 2
  c = gen_lambda2(e[3]) if e.size > 3

  case op
  when 'not'
    '(~%s & mask64)' % [a]
  when *%w| shl1 shr1 shr4 shr16 |
    gen_lambda2_shift(op) % [a]
  when *%w| plus and or xor |
    gen_lambda2_binary(op) % [a, b]
  when 'if0'
    '(%s == 0 ? %s : %s)' % [a, b, c]
    
  when 'fold', 'tfold'
    '(x0 = %s; y0 = %s; f = lambda {|x,y| %s};
      f[(x0 >> 56) & mask8,
      f[(x0 >> 48) & mask8,
      f[(x0 >> 40) & mask8,
      f[(x0 >> 32) & mask8,
      f[(x0 >> 24) & mask8,
      f[(x0 >> 16) & mask8,
      f[(x0 >> 8) & mask8,
      f[(x0 & mask8), y0]]]]]]]] )' % [a, b, c]
    
  else
    raise '! not handled op ' + op
  end
end

def gen_lambda(e)
  # gen_lambda1(e)
  s = 'lambda {|x| mask64 = 0xFFFFFFFFFFFFFFFF; mask8 = 0xFF; '
  s << gen_lambda2(e)
  s << '}'
  Kernel::eval(s)
end
