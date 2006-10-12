require 'set'
require 'test_config'
require 'typelib'
require 'test/unit'
require '.libs/test_rb_value'
require 'pp'

class TC_Value < Test::Unit::TestCase
    include Typelib

    # Not in setup() since we want to make sure
    # that the registry is not destroyed by the GC
    def make_registry
        registry = Registry.new
        testfile = File.join(SRCDIR, "test_cimport.1")
        assert_raises(RuntimeError) { registry.import( testfile  ) }
        registry.import( testfile, "c" )

        registry
    end

    def test_registry
        assert_raises(RuntimeError) { Registry.guess_type("bla.1") }
        assert_equal("c", Registry.guess_type("blo.c"))
        assert_equal("c", Registry.guess_type("blo.h"))
        assert_equal("tlb", Registry.guess_type("blo.tlb"))

        assert_raises(RuntimeError) { Registry.new.import("bla.c") }

        registry = Registry.new
        testfile = File.join(SRCDIR, "test_cimport.h")
        assert_raises(RuntimeError) { registry.import(testfile) }
        assert_nothing_raised {
            registry.import(testfile, nil, :include => [ File.join(SRCDIR, '..') ], :define => [ 'GOOD' ])
        }

        registry = Registry.new
        assert_nothing_raised {
            registry.import(testfile, nil, :rawflag => [ "-I#{File.join(SRCDIR, '..')}", "-DGOOD" ])
        }
        assert_nothing_raised {
            registry.import(testfile, nil, :merge => true, :rawflag => [ "-I#{File.join(SRCDIR, '..')}", "-DGOOD" ])
        }
	assert_raises(RuntimeError) { registry.import(testfile, nil, :rawflag => [ "-I#{File.join(SRCDIR, '..')}", "-DGOOD" ]) }
    end

    def test_type_inequality
        # Check that == returns false when the two objects aren't of the same class
        # (for instance type == nil shall return false)
	type = nil
        type = Registry.new.get("/int")
        assert_equal("/int", type.name)
        assert_nothing_raised { type == nil }
        assert(type != nil)
    end

    def test_to_ruby
	int = Registry.new.get("/int").new
	assert_equal(0, int.to_ruby)

	str = Registry.new.build("/char[20]").new
	assert( String === str.to_ruby )
    end

    def test_value_equality
        type = Registry.new.build("/int")
	v1 = type.new.zero!
	v2 = type.new.zero!
	assert_equal(v1, v2)
	assert(! v1.eql?(v2))
	
        registry = make_registry
        a_type = registry.get("/struct A")
        a1 = a_type.new :a => 10, :b => 20, :c => 30, :d => 40
        a2 = a_type.new :a => 10, :b => 20, :c => 30, :d => 40
	assert_equal(a1, a2)
	assert(! a1.eql?(a2))
    end

    def test_pointer_type
        type = Registry.new.build("/int*")
        assert_not_equal(type, type.deference)
        assert_not_equal(type, type.to_ptr)
        assert_not_equal(type.to_ptr, type.deference)
        assert_equal(type, type.deference.to_ptr)
        assert_equal(type, type.to_ptr.deference)

	value = type.new
	value.zero!
	assert(value.null?)
	assert_equal(nil, value.to_ruby)
    end
    def test_pointer_value
        type  = Registry.new.build("/int")
        value = type.new
        assert_equal(value.class, type)
        ptr   = value.to_ptr
        assert_equal(value, ptr.deference)
    end

    def test_string_handling
        buffer_t = Registry.new.build("/char[256]")
        buffer = buffer_t.new
	assert( buffer.string_handler? )
	assert( buffer.respond_to?(:to_str) )
	assert( buffer.respond_to?(:from_str) )

	int_value = Registry.new.get("/int").new
	assert( !int_value.respond_to?(:to_str) )
	assert( !int_value.respond_to?(:from_str) )
        
        # Check that .from_str.to_str is an identity
        assert_equal("first test", buffer.from_str("first test").to_str)
	assert_equal("first test", buffer.to_ruby)
        assert_raises(ArgumentError) { buffer.from_str("a"*512) }
    end

    def test_pretty_printing
        b = make_registry.get("/struct B").new
	b.zero!
	assert_nothing_raised { pp b }

    end

    def test_to_csv
	klass = make_registry.get("/struct DisplayTest")
	assert_equal("t.fields[0] t.fields[1] t.fields[2] t.fields[3] t.f t.d t.a.a t.a.b t.a.c t.a.d t.mode", klass.to_csv('t'));
	assert_equal(".fields[0] .fields[1] .fields[2] .fields[3] .f .d .a.a .a.b .a.c .a.d .mode", klass.to_csv);
	assert_equal(".fields[0],.fields[1],.fields[2],.fields[3],.f,.d,.a.a,.a.b,.a.c,.a.d,.mode", klass.to_csv('', ','));

	value = klass.new
	value.fields[0] = 0;
	value.fields[1] = 1;
	value.fields[2] = 2;
	value.fields[3] = 3;
	value.f = 1.1;
	value.d = 2.2;
	value.a.a = 10;
	value.a.b = 20;
	value.a.c = 'b';
	value.a.d = 42;
	assert_equal("0 1 2 3 1.1 2.2 10 20 b 42 OUTPUT", value.to_csv)
	assert_equal("0,1,2,3,1.1,2.2,10,20,b,42,OUTPUT", value.to_csv(','))
    end
	

    def test_is_a
        registry = make_registry
        a = registry.get("/struct A").new
	assert( a.is_a?("/struct A") )
	assert( a.is_a?("/long") )
	assert( a.is_a?(/ A$/) )
    end

    def test_to_s
	int_value = Registry.new.get("/int").new
	int_value.zero!
	assert_equal("0", int_value.to_s)
    end

end
