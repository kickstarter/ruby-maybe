require "contracts"

class MaybeOf < Contracts::CallableClass
  def initialize(*values)
    @values = values
  end

  def valid?(obj)
    obj.is_a?(Nothing) || obj.is_a?(Just) && @values.any? {|v| Contract.valid?(obj.get, v) }
  end
end

# NOTE: Nothing and Just need to be initialized ahead of time so they're available
# for Contract definitions below.

Nothing = Class.new
Just = Class.new

# Maybe is a union type that is expressed in terms of Nothing and Just. It is
# useful for gracefully handling potentially null values:
#
# @example when value is non-null
#   User.create!(email: "john@doe.com", name: "John Doe")
#
#   Maybe
#     .from_nullable(User.find_by(email: "john@doe.com"))
#     .map {|user| user.name }
#     .get_or_else { "NO NAME" }
#
#   #=> "John Doe"
#
# @example when value is null
#   Maybe
#     .from_nullable(User.find_by(email: "not@present.com"))
#     .map {|user| user.name }
#     .get_or_else { "NO NAME" }
#
#   #=> "NO NAME"
#
module Maybe
  include Contracts::Core
  C = Contracts
  private_constant :C

  # An alias for instantiating a Nothing object
  #
  # @example
  #   Maybe.Nothing
  #   #=> Nothing
  #
  # @returns [Nothing] an instance of Nothing
  Contract C::None => Nothing
  def self.Nothing
    Nothing.instance
  end

  # An alias for instantiating a Just object
  #
  # @example
  #   Maybe.Just(1)
  #   #=> Just(1)
  #
  # @param value [Any] the value to wrap
  # @returns [Just<Any>] an instance of Just wrapping some object
  Contract C::Any => Just
  def self.Just(value)
    Just.new(value)
  end

  # An alias for instantiating a Just object
  #
  # @example
  #   Maybe.of(1)
  #   #=> Just(1)
  #
  # @param value [Any] the value to wrap
  # @returns [Just<Any>] an instance of Just wrapping the value
  Contract C::Any => Just
  def self.of(value)
    Just.new(value)
  end

  # Takes a nullable object and returns either an instance of Just wrapping
  # the object in the case that the object is non-null, or an instance of
  # Nothing in the case that the object is null.
  #
  # @example with a non-null value
  #   User.create(email: "john@doe.com")
  #
  #   Maybe.from_nullable(User.find_by(email: "john@doe.com"))
  #   #=> Just(1)
  #
  # @example with a null value
  #   Maybe.from_nullable(User.find_by(email: "not@present.com"))
  #   #=> Nothing
  #
  # @param value [Any] the value to wrap
  # @returns [Just<Any>,Nothing] either an instance of Just wrapping the value,
  # or an instance of Nothing
  Contract C::Any => Maybe
  def self.from_nullable(value)
    value.nil? ? Nothing.instance : Just.new(value)
  end

  # Takes a set of Maybes, and attempts to combine their values, and wrap them
  # into a single Maybe.
  #
  # @example with a single instance of Just
  #   Maybe.zip(Maybe.Just(1))
  #   #=> Just(1)
  #
  # @example with a single instance of Nothing
  #   Maybe.zip(Maybe.Nothing)
  #   #=> Nothing
  #
  # @example with multiple instances of Just
  #   Maybe.zip(Maybe.Just(1), Maybe.Just(2))
  #   #=> Just([1,2])
  #
  # @example with multiple instances of Nothing
  #   Maybe.zip(Maybe.Nothing, Maybe.Nothing)
  #   #=> Nothing
  #
  # @example a mixture of Just and Nothing instances
  #   Maybe.zip(Maybe.Just(1), Maybe.Nothing, Maybe.Just(2))
  #   #=> Nothing
  #
  # @param m [Array<Just<Any>>, Array<Nothing>] a collection of Maybes
  # @return [Just<Any>,Nothing] either a combined Just, or Nothing
  Contract C::Args[Maybe] => C::Or[Maybe]
  def self.zip(fst, snd, *rest)
    [fst, snd, *rest].reduce(Just([])) do |accum, maybe|
      accum.flat_map do |accum_|
        maybe.map {|maybe_| accum_ + [maybe_] }
      end
    end
  end

  # Takes a function and a set of Maybes, and attempts to apply the function
  # and return the result wrapped in a Maybe.
  #
  # @example with a single instance of Just
  #   Maybe.lift(->(n){ n ** 2 }, Maybe.Just(3))
  #   #=> Just(9)
  #
  # @example with a single instance of Nothing
  #   Maybe.lift(->(n){ n ** 2 }, Maybe.Nothing)
  #   #=> Nothing
  #
  # @example with multiple instances of Just
  #   Maybe.lift(->(x,y){ x + y }, Maybe.Just(1), Maybe.Just(2))
  #   #=> Just(3)
  #
  # @example with multiple instances of Nothing
  #   Maybe.lift(->(x,y){ x + y }, Maybe.Nothing, Maybe.Nothing)
  #   #=> Nothing
  #
  # @example a mixture of Just and Nothing instances
  #   Maybe.lift(->(x,y,z) { x + y + z }, Maybe.Just(1), Maybe.Nothing, Maybe.Just(2))
  #   #=> Nothing
  #
  # @example called with the wrong number of arguments
  #   Maybe.lift(->(x,y) { x + y }, Maybe.Just(1))
  #   #=> ArgumentError: wrong number of arguments (given 1, expected 2)
  #
  # @param f [Proc] a function
  # @param m [Array<Just<Any>>, Array<Nothing>] a collection of Maybes
  # @return [Just<Any>,Nothing] either the result wrapped in a Just, or Nothing
  Contract Proc, C::Args[Maybe] => Maybe
  def self.lift(f, fst, *rst)
    [fst, *rst]
      .reduce(Just([])) {|accum, maybe|
        accum.flat_map {|accum_|
          maybe.map {|maybe_| accum_ + [maybe_] }
        }
      }
      .ap( Just(->(args){ f.call(*args) }) )
  end
end

# Nothing is a member of the Maybe union type that represents a null value.
# It's used in conjunction with the Just type to allow one to gracefully handle
# null values without having to create a large amount of conditional logic.
class Nothing
  include Maybe
  include Contracts::Core
  C = Contracts
  private_constant :C

  NothingError = Class.new(RuntimeError)

  def self.instance
    @instance ||= new
  end
  private_class_method :new

  # Attempts to return the value wrapped by the Maybe type. In the case of a
  # Nothing, however, it will raise due to the fact that Nothing cannot hold a
  # value.
  #
  # @example
  #   Maybe.Nothing.get
  #   #=> Nothing::NothingError: cannot get the value of Nothing.
  #
  # @raises [Nothing::NothingError] an error raised when one attempts to fetch the value
  Contract C::None => C::None
  def get
    raise NothingError, "cannot get the value of Nothing."
  end

  # Attempts to either return the value wrapped by the Maybe type (in the case
  # of a Just), or provide an alternative value when the instance is a Nothing.
  #
  # @example
  #   Maybe.Nothing.get_or_else { "NO NAME" }
  #   #=> "NO NAME"
  #
  # @yield [] the alternative value when called on an instance of Nothing
  # @return [Any] either the value contained by the Maybe or the value
  # returned by the block passed.
  Contract C::Func[C::None => C::Any] => C::Any
  def get_or_else(&f)
    f.call
  end

  # A convenience method for determining whether a Maybe type is an instance
  # of Just.
  # @return [Boolean] whether or not the value is a Just
  Contract C::None => C::Bool
  def just?
    false
  end

  # A convenience method for determining whether a Maybe type is an instance
  # of Nothing.
  # @return [Boolean] whether or not the value is a Nothing
  Contract C::None => C::Bool
  def nothing?
    true
  end

  # Transforms a Maybe type into a Maybe of the same type. When called on an
  # instance of Just it will apply the block with its value as an argument, and
  # re-wrap the result of the block in another Just. When called on an instance
  # of Nothing, however, the method will no-op and simply return itself.
  #
  # @example
  #   Maybe.Nothing.map {|num| num + 1 }
  #   #=> Nothing
  #
  # @yield [value] the block to apply
  # @yieldparam [Any] the value wrapped by the Maybe type
  # @yieldreturn [Any] the value returned by the block
  # @return [Nothing] the instance of Nothing
  Contract C::Func[C::Any => C::Any] => Nothing
  def map(&f)
    self
  end

  # Transforms a Maybe type into another Maybe (not necessarily of the same type).
  # When called on an instance of Just it will will apply the block with its value
  # as the argument (it differs from Maybe#map in that it is the responsibility
  # of the caller to rewrap the result in a Maybe type). When called on an instance
  # of Nothing the method will no-op and simply return itself.
  #
  # @example
  #   Maybe.Nothing.flat_map {|num| num == 0 ? Maybe.Just(num) : Maybe.Nothing }
  #   #=> Nothing
  #
  # @yield [value] the block to apply
  # @yieldparam [Any] the value wrapped by the Maybe type
  # @yieldreturn [Nothing, Just<Any>] the Maybe returned by the block
  # @return [Nothing] the Maybe returned by the block
  Contract C::Func[C::Any => Maybe] => Nothing
  def flat_map(&f)
    self
  end

  # Applies the function inside a Maybe type to another applicative type.
  #
  # @example
  #   Maybe.Nothing.ap( Maybe.of(->(str){ str.upcase }) )
  #   #=> Nothing
  #
  # @param m [Just<Proc>, Nothing] an instance of the Maybe type to apply
  # @return [Nothing] the result of applying the function wrapped in a Maybe
  Contract MaybeOf[Proc] => Nothing
  def ap(m)
    self
  end
  alias apply ap

  # An equality operator
  #
  # @example
  #   Maybe.Nothing == Maybe.Nothing
  #   #=> true
  #
  # @param m [Any] the object to compare against
  # @return [Boolean] whether or not the object is equal
  Contract C::Any => C::Bool
  def ==(m)
    m.is_a?(Nothing)
  end

  # Overrides the default print behavior
  #
  # @example
  #   puts(Maybe.Nothing)
  #   #=> "Nothing"
  #
  # @return [String] the String to print
  Contract C::None => String
  def inspect
    "Nothing"
  end
end

# Just is a member of the Maybe union type that represents a non-null value.
# It's used in conjunction with the Nothing type to allow one to gracefully
# handle null values without having to create a large amount of conditional
# logic.
class Just
  include Maybe
  include Contracts::Core
  C = Contracts
  private_constant :C

  def initialize(value)
    @value = value
  end

  # Attempts to return the value wrapped by the Maybe type. In the case of a
  # Nothing, however, it will raise due to the fact that Nothing cannot hold a
  # value.
  #
  # @example
  #   Maybe.Just(1).get
  #   #=> 1
  #
  # @return [Any] the value wrapped by the Maybe object
  Contract C::None => C::Any
  def get
    @value
  end

  # Attempts to either return the value wrapped by the Maybe type (in the case
  # of a Just), or provide an alternative value when the instance is a Nothing.
  #
  # @example
  #   Maybe.Just("John Doe").get_or_else { "NO NAME" }
  #   #=> "John Doe"
  #
  # @yield [] the alternative value when called on an instance of Nothing
  # @return [Any] the value wrapped by the Maybe object
  Contract C::Func[C::None => C::Any] => C::Any
  def get_or_else(&f)
    @value
  end

  # A convenience method for determining whether a Maybe type is an instance
  # of Just.
  # @return [Boolean] whether or not the value is a Just
  Contract C::None => C::Bool
  def just?
    true
  end

  # A convenience method for determining whether a Maybe type is an instance
  # of Nothing.
  # @return [Boolean] whether or not the value is a Nothing
  Contract C::None => C::Bool
  def nothing?
    false
  end

  # Transforms a Maybe type into a Maybe of the same type. When called on an
  # instance of Just it will apply the block with its value as an argument, and
  # re-wrap the result of the block in another Just. When called on an instance
  # of Nothing, however, the method will no-op and simply return itself.
  #
  # @example
  #   Maybe.Just(1).map {|num| num + 1 }
  #   #=> Just(2)
  #
  # @yield [value] the block to apply
  # @yieldparam [Any] the value wrapped by the Maybe type
  # @yieldreturn [Any] the value returned by the block
  # @return [Just<Any>] the value returned by the block and wrapped by a Maybe
  Contract C::Func[C::Any => C::Any] => Just
  def map(&f)
    flat_map {|value| Maybe.of(f.call(value)) }
  end

  # Transforms a Maybe type into another Maybe (not necessarily of the same type).
  # When called on an instance of Just it will will apply the block with its value
  # as the argument (it differs from Maybe#map in that it is the responsibility
  # of the caller to rewrap the result in a Maybe type). When called on an instance
  # of Nothing the method will no-op and simply return itself.
  #
  # @example
  #   User.create!(email: "john@doe.com", slug: "johndoe")
  #   Maybe
  #     .from_nullable(User.find_by(email: "john@doe.com"))
  #     .flat_map {|u| u.slug == "johndoe" ? Maybe.Just(u) : Maybe.Nothing }
  #
  #   #=> Just(#<User email: "john@doe.com", slug: "johndoe">)
  #
  # @yield [value] the block to apply
  # @yieldparam [Any] the value wrapped by the Maybe type
  # @yieldreturn [Nothing, Just<Any>] the Maybe returned by the block
  # @return [Nothing, Just<Any>] the Maybe returned by the block
  Contract C::Func[C::Any => Maybe] => Maybe
  def flat_map(&f)
    f.call(@value)
  end

  # Applies the function inside a Maybe type to another applicative type.
  #
  # @example
  #   Maybe.of("hello, world!").ap( Maybe.of(->(str){ str.upcase }) )
  #   #=> Just("HELLO, WORLD!")
  #
  # @param m [Just<Proc>, Nothing] an instance of the Maybe type to apply
  # @return [Just<Any>, Nothing] the result of applying the function wrapped in a Maybe
  Contract MaybeOf[Proc] => Maybe
  def ap(m)
    m.flat_map {|f| map(&f) }
  end
  alias apply ap

  # An equality operator
  #
  # @example
  #   Maybe.Just(1) == Maybe.Just(1)
  #   #=> true
  #
  #   Maybe.Just(0) == Maybe.Just(1)
  #   #=> false
  #
  # @param m [Any] the object to compare against
  # @return [Boolean] whether or not the object is equal
  Contract C::Any => C::Bool
  def ==(m)
    m.is_a?(Just) && m.get == get
  end

  # Overrides the default print behavior
  #
  # @example
  #   puts(Maybe.Just(1))
  #   #=> "Just(1)"
  #
  # @return [String] the String to print
  Contract C::None => String
  def inspect
    "Just(#{@value.inspect})"
  end
end
