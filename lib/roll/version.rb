module Roll

  # = Version Number
  #
  # The Version class is essentially a tuple (immutable array) with special
  # comparision operators.
  #
  class Version

    include Comparable
    include Enumerable

    # Convenience alias for ::new.
    def self.[](*args)
      new(*args)
    end

    # Parses a string constraint returning the operation as a lambda.
    def self.constraint_lambda(constraint)
      op, val = *parse_constraint(constraint)
      lambda do |t|
        case t
        when Version
          t.send(op, val)
        else
          Version.new(t).send(op, val)
        end
      end
    end

    # Converts a constraint into an operator and value.
    def self.parse_constraint(constraint)
      constraint = constraint.strip
      re = %r{^(=~|~>|<=|>=|==|=|<|>)?\s*(\d+(:?\.\S+)*)$}
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

    # New version number.
    #
    # TODO: parse YAML style versions
    def initialize(*args)
      args   = args.flatten.compact
      args   = args.join('.').split(/\W+/)
      @tuple = args.map{ |i| /^\d+$/ =~ i.to_s ? i.to_i : i }
    end

    # Returns string representation of version, e.g. "1.0.0".
    def to_s
      @tuple.compact.join('.')
    end

    # This is here only becuase File.join calls it instead of to_s.
    def to_str
      @tuple.compact.join('.')
    end

    #def inspect; to_s; end

    # Access indexed segment of version number.
    # Returns 0 if index is non-existant.
    def [](i)
      @tuple.fetch(i,0)
    end

    # "Spaceship" comparsion operator.
    def <=>(other)
      [size, other.size].max.times do |i|
        c = self[i] <=> (other[i] || 0)
        return c if c != 0
      end
      0
    end

    # Pessimistic constraint (like '~>' in gems).
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

    # Patch is third number in the version series.
    def patch ; @tuple[2] || 0 ; end

    # Build returns the remaining portions of the version
    # tuple after +patch+ joined by '.'.
    def build
      @tuple[3..-1].join('.')
    end

    # Iterate over each version segment.
    def each(&block)
      @tuple.each(&block)
    end

    # Size of version tuple.
    def size
      @tuple.size
    end

    # Delegate to the array.
    #def method_missing(sym, *args, &blk)
    #  @tuple.__send__(sym, *args, &blk) rescue super
    #end

    protected

    def tuple ; @tuple ; end

    # Parse YAML-based VERSION.
    def parse_version_yaml(yaml)
      require 'yaml'
      data = YAML.load(yaml)
      data = data.inject({}){ |h,(k,v)| h[k.to_sym] = v; h }
      self.name = data[:name] if data[:name]
      self.date = data[:date] if data[:date]
      # jeweler
      if data[:major]
        self.version = data.values_at(:major, :minor, :patch, :build).compact.join('.')
      else
        vers = data[:vers] || data[:version]
        self.version = (Array === vers ? vers.join('.') : vers)
      end
      self.codename = data.values_at(:code, :codename).compact.first
    end

  end

  # VersionError is raised when a requested version cannot be found.
  class VersionError < ::RangeError  # :nodoc:
  end

  # VersionConflict is raised when selecting another version
  # of a library when a previous version has already been selected.
  class VersionConflict < ::LoadError  # :nodoc:
  end

end
