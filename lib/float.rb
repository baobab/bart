require 'rational'

class Float
  def to_r(n=14)
    return Rational(0,1) if zero?
    e = n-Math.log(self).round
    Rational((self*(2**e)).to_i, 2**e)
  end
  
  def proximity(other)
    self < other ? other/self : self/other
  end
  
  def rp(*a)
    to_r(*a).to_f.proximity(self)
  end
end

