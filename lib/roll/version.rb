module Roll

  # = Version Number
  #
  # Essentially a tuple (immutable array).
  class Version

    #include Enumerable
    include Comparable

  # metaclass
  class << self
    # Convenience alias for ::new.

    def [](*args)
      new(*args)
    end

    # Parses a string constraint returning the operation as a lambda.

    def constraint_lambda(constraint)
      op, val = *parse_constraint(constraint)
      lambda{ |t| t.send(op, val) }
    end

    # Converts a constraint into an operator and value.

    def parse_constraint(constraint)
      constraint = constraint.strip
      re = %r{^(=~|~>|<=|>=|==|=|<|>)?\s*(\d+(:?[-.]\d+)*)$}
      if md = re.match(constraint)
        if op = md[1]
          op = '=~' if op == '~>'
          op = '==' if op == '='
          val = new(*md[2].split(/\W+/))
        else
          op = '=='
          val = new(*constraint.split(/\W+/))
        end
      else
        raise ArgumentError, "invalid constraint"
      end
      return op, val
    end
  end

  private

    # TODO: deal with string portions of version number
    def initialize(*args)
      args = args.join('.').split(/\W+/)
      @tuple = args.collect { |i| i.to_i }
      #@tuple.extend(Comparable)
    end

  public

    def to_s ; @tuple.join('.') ; end

    # This is here only becuase File.join calls it instead of to_s.
    def to_str ; @tuple.join('.') ; end

    #def inspect; to_s; end

    def [](i)
      @tuple.fetch(i,0)
    end

    # "Spaceship" comparsion operator.

    def <=>(other)
      #other = other.to_t
      [@tuple.size, other.size].max.times do |i|
        c = (@tuple[i] || 0) <=> (other[i] || 0)
        return c if c != 0
      end
      0
    end

    # For pessimistic constraint (like '~>' in gems).

    def =~(other)
      #other = other.to_t
      upver = other.tuple.dup
      i = upver.index(0)
      i = upver.size unless i
      upver[i-1] += 1
      self >= other && self < upver
    end

    # Major is the first number in the version series.

    def major ; @tuple[0] ; end

    # Minor is the second number in the version series.

    def minor ; @tuple[1] || 0 ; end

    # Teeny is third number in the version series.

    def patch ; @tuple[2] || 0 ; end

    # Delegate to the array.

    def method_missing(sym, *args, &blk)
      @tuple.send(sym, *args, &blk) rescue super
    end

  protected

    def tuple ; @tuple ; end

  end

end

