require "test_helper"

require_relative "../lib/ksr/maybe"

class Ksr::MaybeTest < ActiveSupport::TestCase
  context ".Nothing" do
    should "return an instance of Nothing" do
      assert_equal Ksr::Nothing.instance, Ksr::Maybe.Nothing
    end
  end

  context ".Just" do
    should "return an instance of Just" do
      assert_equal Ksr::Maybe.of(1), Ksr::Maybe.Just(1)
    end
  end

  context ".of" do
    should "return an instance of Just" do
      assert_equal Ksr::Just.new(1), Ksr::Maybe.of(1)
    end
  end

  context ".from_nullable" do
    context "when value is `nil`" do
      should "return an instance of Nothing" do
        assert_equal Ksr::Nothing.instance, Ksr::Maybe.from_nullable(nil)
      end
    end

    context "when value is not `nil`" do
      should "return an instance of Just" do
        assert_equal Ksr::Maybe.of(1), Ksr::Maybe.from_nullable(1)
      end
    end
  end

  context ".zip" do
    setup do
      @just = Ksr::Maybe.of(1)
      @nothing = Ksr::Nothing.instance
    end

    context "with only Just values" do
      should "return an instance of Just" do
        assert_equal Ksr::Maybe.of([1,1]), Ksr::Maybe.zip(@just, @just)
      end
    end

    context "with only Nothing values" do
      should "return an instance of Nothing" do
        assert_equal Ksr::Nothing.instance, Ksr::Maybe.zip(@nothing, @nothing)
      end
    end

    context "with a mixture of Just and Nothing values" do
      should "return an instance of Nothing" do
        assert_equal Ksr::Nothing.instance, Ksr::Maybe.zip(@just, @nothing, @just)
      end
    end
  end

  context "Nothing" do
    subject do
      Ksr::Nothing.instance
    end

    context "#get" do
      should "raise an error" do
        assert_raise(Ksr::Nothing::NothingError) { subject.get }
      end
    end

    context "#get_or_else" do
      should "call the block" do
        assert_equal 1, subject.get_or_else { 1 }
      end
    end

    context "#just?" do
      should "return false" do
        refute subject.just?
      end
    end

    context "#nothing?" do
      should "return true" do
        assert subject.nothing?
      end
    end

    context "#map" do
      should "return self" do
        assert_equal subject, subject.map {|_n| 1 }
      end
    end

    context "#flat_map" do
      should "return self" do
        assert_equal subject, subject.flat_map {|_n| 1 }
      end
    end

    context "#ap" do
      should "return self" do
        assert_equal subject, subject.ap(Ksr::Maybe.of(->(x){ x + 1 }))
      end
    end

    context "#==" do
      context "when object is a Nothing" do
        should "return true" do
          assert_equal subject, Ksr::Nothing.instance
        end
      end

      context "when object is a Just" do
        should "return false" do
          refute_equal subject, Ksr::Maybe.of(1)
        end
      end
    end

    context "#inspect" do
      should "return the correct String" do
        assert_equal "Nothing", subject.inspect
      end
    end
  end

  context "Just" do
    subject do
      Ksr::Maybe.of(1)
    end

    context "#get" do
      should "return the value" do
        assert_equal 1, subject.get
      end
    end

    context "#get_or_else" do
      should "return the value" do
        assert_equal 1, subject.get_or_else { 2 }
      end
    end

    context "#just?" do
      should "return true" do
        assert subject.just?
      end
    end

    context "#nothing?" do
      should "return false" do
        refute subject.nothing?
      end
    end

    context "#map" do
      setup do
        @f = ->(n){ n + 1 }
        @g = ->(n){ n * 2 }
      end

      should "hold to the law of identity" do
        assert_equal subject, subject.map {|x| x }
      end

      should "hold to the law of composition" do
        assert_equal subject.map(&@g).map(&@f), subject.map {|n| @f.call(@g.call(n)) }
      end
    end

    context "#flat_map" do
      setup do
        @f = ->(n) { Ksr::Maybe.of(n + 1) }
        @g = ->(n) { Ksr::Maybe.of(n * 2) }
      end

      should "fail if the function does not rewrap the value" do
        assert_raises(ReturnContractError) { subject.flat_map {|x| x } }
      end

      should "be equivalent to calling the function with the held value" do
        assert_equal @f.call(subject.get), subject.flat_map(&@f)
      end

      should "be equivalent when the function merely rewraps" do
        assert_equal subject, subject.flat_map(&Ksr::Maybe.method(:of))
      end

      should "hold to the law of associativity" do
        assert_equal subject.flat_map(&@f).flat_map(&@g), subject.flat_map {|v| @f.call(v).flat_map(&@g) }
      end
    end

    context "#ap" do
      setup do
        @identity = ->(x){ x }
        @upcase = ->(str){ str.upcase }
        @add = ->(n){ n + 1 }
      end

      should "raise if argument is not an instance of Maybe" do
        assert_raises(ContractError) { Ksr::Maybe.of(1).ap(->(x){ x + 1 }) }
      end

      should "raise if argument is not a Maybe holding a function" do
        assert_raises(ContractError) { Ksr::Maybe.of(1).ap(Ksr::Maybe.of(1)) }
      end

      should "work when given a Maybe holding a function" do
        assert_equal Ksr::Maybe.of("HELLO, WORLD!"), Ksr::Maybe.of("hello, world!").ap(Ksr::Maybe.of(@upcase))
      end

      should "hold to the law of identity" do
        assert_equal Ksr::Maybe.of(1), Ksr::Maybe.of(1).ap(Ksr::Maybe.of(@identity))
      end
    end

    context "#==" do
      context "when object is a Just that is equivalent" do
        should "return true" do
          assert_equal Ksr::Maybe.of(1), Ksr::Maybe.of(1)
        end
      end

      context "when object is a Just that is equivalent" do
        should "return false" do
          refute_equal Ksr::Maybe.of(1), Ksr::Maybe.of(2)
        end
      end

      context "when object is a Nothing" do
        should "return false" do
          refute_equal Ksr::Nothing.instance, Ksr::Maybe.of(1)
        end
      end
    end

    context "#inspect" do
      should "return the correct String" do
        assert_equal "Just(1)", Ksr::Maybe.of(1).inspect
      end
    end
  end
end
