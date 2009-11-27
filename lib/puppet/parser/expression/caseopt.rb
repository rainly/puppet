require 'puppet/parser/expression/branch'

class Puppet::Parser::Expression
  # Each individual option in a case statement.
  class CaseOpt < Expression::Branch
    attr_accessor :value, :statements

    # CaseOpt is a bit special -- we just want the value first,
    # so that CaseStatement can compare, and then it will selectively
    # decide whether to fully evaluate this option

    def each
      [@value,@statements].each { |child| yield child }
    end

    # Are we the default option?
    def default?
      # Cache the @default value.
      return @default if defined?(@default)

      if @value.is_a?(Expression::ArrayConstructor)
        @value.each { |subval|
          if subval.is_a?(Expression::Default)
            @default = true
            break
          end
        }
      else
        @default = true if @value.is_a?(Expression::Default)
      end

      @default ||= false

      return @default
    end

    # You can specify a list of values; return each in turn.
    def eachvalue(scope)
      if @value.is_a?(Expression::ArrayConstructor)
        @value.each { |subval|
          yield subval.denotation
        }
      else
        yield @value.denotation
      end
    end

    def eachopt
      if @value.is_a?(Expression::ArrayConstructor)
        @value.each { |subval|
          yield subval
        }
      else
        yield @value
      end
    end

    # Evaluate the actual statements; this only gets called if
    # our option matched.
    def compute_denotation
      return @statements.denotation
    end
  end
end