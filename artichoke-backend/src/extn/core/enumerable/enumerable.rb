# frozen_string_literal: true

##
# Enumerable
#
module Enumerable
  def all?(*args, &block)
    if !args.empty?
      each do |val|
        # case equality === is part of the spec
        # rubocop:disable Style/CaseEquality
        return false unless args[0] === val
        # rubocop:enable Style/CaseEquality
      end
    elsif block
      each { |val| return false unless block.call(val) }
    else
      each { |val| return false unless val }
    end
    true
  end

  def any?(*args, &block)
    if !args.empty?
      each do |val|
        # case equality === is part of the spec
        # rubocop:disable Style/CaseEquality
        return true if args[0] === val
        # rubocop:enable Style/CaseEquality
      end
    elsif block
      each { |val| return true if block.call(val) }
    else
      each { |val| return true if val }
    end
    false
  end

  def collect(&block)
    return to_enum :collect unless block

    ary = []
    each { |val| ary.push(block.call(val)) }
    ary
  end

  def count(*args, &block)
    count = 0
    if block
      each do |val|
        count += 1 if block.call(val)
      end
    elsif args.empty?
      each { count += 1 }
    else
      each do |val|
        count += 1 if val == args[0]
      end
    end
    count
  end

  def cycle(nval = nil, &block)
    return to_enum(:cycle, nval) unless block

    n = nil

    if nval.nil?
      n = -1
    else
      n = nval.to_i
      return nil if n <= 0
    end

    ary = []
    each do |*i|
      ary.push(i)
      yield(*i)
    end
    return nil if ary.empty?

    while n.negative? || (n -= 1).positive?
      ary.each do |i|
        yield(*i)
      end
    end

    nil
  end

  def detect(ifnone = nil, &block)
    return to_enum :detect, ifnone unless block

    each do |val|
      return val if block.call(val)
    end
    ifnone&.call
  end

  def drop(size)
    size = size.to_i
    raise ArgumentError, 'attempt to drop negative size' if size.negative?

    ary = []
    each do |val|
      if size.zero?
        ary << val
      else
        size -= 1
      end
    end
    ary
  end

  def drop_while(&block)
    return to_enum :drop_while unless block

    ary = []
    state = false
    each do |val|
      state ||= !block.call(val)
      ary << val if state
    end
    ary
  end

  def each_cons(size, &block)
    size = size.to_i
    raise ArgumentError, 'invalid size' if size <= 0

    return to_enum(:each_cons, size) unless block

    ary = []
    size = size.to_i
    each do |val|
      ary.shift if ary.size == size
      ary << val
      block.call(ary.dup) if ary.size == size
    end
    nil
  end

  def each_slice(size, &block)
    size = size.to_i
    raise ArgumentError, 'invalid slice size' if size <= 0

    return to_enum(:each_slice, size) unless block

    ary = []
    size = size.to_i
    each do |val|
      ary << val
      if ary.size == size
        block.call(ary)
        ary = []
      end
    end
    block.call(ary) unless ary.empty?
    nil
  end

  def each_with_index(&block)
    return to_enum :each_with_index unless block

    i = 0
    each do |val|
      block.call(val, i)
      i += 1
    end
    self
  end

  def each_with_object(obj, &block)
    return to_enum(:each_with_object, obj) unless block

    each { |val| block.call(val, obj) }
    obj
  end

  def entries
    ary = []
    each do |val|
      ary.push(val)
    end
    ary
  end

  def find_all(&block)
    return to_enum :find_all unless block

    ary = []
    each do |val|
      ary.push(val) if block.call(val)
    end
    ary
  end

  def find_index(*args, &block)
    return to_enum(:find_index, *args) if !block && args.empty?

    idx = 0
    if block
      each do |elem|
        return idx if block.call(elem)

        idx += 1
      end
    else
      each do |elem|
        return idx if elem == args[0]

        idx += 1
      end
    end
    nil
  end

  def first(*args)
    case args.length
    when 0
      each do |val| # rubocop:disable Lint/UnreachableLoop
        return val
      end
      nil
    when 1
      i = args[0].to_i
      raise ArgumentError, 'attempt to take negative size' if i.negative?

      return [] if i.zero?

      ary = Array.new(i) # Array::with_capacity(i)
      idx = 0

      each do |val|
        ary[idx] = val
        idx += 1
        break if idx == i
      end
      ary
    else
      raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 0..1)"
    end
  end

  def flat_map(&block)
    return to_enum :flat_map unless block

    ary = []
    each do |elem|
      elem2 = block.call(elem)
      if elem2.respond_to? :each
        elem2.each { |elem3| ary.push(elem3) }
      else
        ary.push(elem2)
      end
    end
    ary
  end

  def grep(pattern, &block)
    ary = []
    each do |val|
      if pattern === val # rubocop:disable Style/CaseEquality
        if block
          ary.push(block.call(val))
        else
          ary.push(val)
        end
      end
    end
    ary
  end

  def group_by(&block)
    return to_enum :group_by unless block

    groups = {}
    each do |val|
      group = block.call(val)
      values = groups.fetch(group, [])
      values << val
      groups[group] = values
    end
    groups
  end

  def include?(obj)
    each do |val|
      return true if val == obj
    end
    false
  end

  def inject(*args, &block)
    raise ArgumentError, 'too many arguments' if args.size > 2

    if args[-1].is_a?(Symbol)
      sym = args[-1]
      block = ->(x, y) { x.__send__(sym, y) }
      args.pop
    end
    if args.empty?
      flag = true # no initial argument
      result = nil
    else
      flag = false
      result = args[0]
    end
    each do |val|
      if flag
        # push first element as initial
        flag = false
        result = val
      else
        result = block.call(result, val)
      end
    end
    result
  end

  def max(&block)
    flag = true # 1st element?
    result = nil
    each do |val|
      if flag
        # 1st element
        result = val
        flag = false
      elsif block
        result = val if block.call(val, result) > 0 # rubocop:disable Style/NumericPredicate
      elsif (val <=> result) > 0 # rubocop:disable Style/NumericPredicate
        result = val
      end
    end
    result
  end

  def max_by(&block)
    return to_enum :max_by unless block

    first = true
    max = nil
    max_cmp = nil

    each do |val|
      if first
        max = val
        max_cmp = block.call(val)
        first = false
      elsif (cmp = block.call(val)) > max_cmp
        max = val
        max_cmp = cmp
      end
    end
    max
  end

  def min(&block)
    flag = true # 1st element?
    result = nil
    each do |val|
      if flag
        # 1st element
        result = val
        flag = false
      elsif block
        result = val if block.call(val, result) < 0 # rubocop:disable Style/NumericPredicate
      elsif (val <=> result) < 0 # rubocop:disable Style/NumericPredicate
        result = val
      end
    end
    result
  end

  def min_by(&block)
    return to_enum :min_by unless block

    first = true
    min = nil
    min_cmp = nil

    each do |val|
      if first
        min = val
        min_cmp = block.call(val)
        first = false
      elsif (cmp = block.call(val)) < min_cmp
        min = val
        min_cmp = cmp
      end
    end
    min
  end

  def minmax(&block)
    max = nil
    min = nil
    first = true

    each do |val|
      if first
        max = val
        min = val
        first = false
      elsif block
        max = val if block.call(val, max).positive?
        min = val if block.call(val, min).negative?
      else
        max = val if (val <=> max).positive?
        min = val if (val <=> min).negative?
      end
    end
    [min, max]
  end

  def minmax_by(&block)
    return to_enum :minmax_by unless block

    max = nil
    max_cmp = nil
    min = nil
    min_cmp = nil
    first = true

    each do |val|
      if first
        max = min = val
        max_cmp = min_cmp = block.call(val)
        first = false
      elsif (cmp = block.call(val)) > max_cmp
        max = val
        max_cmp = cmp
      elsif (cmp = block.call(val)) < min_cmp
        min = val
        min_cmp = cmp
      end
    end
    [min, max]
  end

  def none?(*args, &block)
    if !args.empty?
      each do |val|
        # case equality === is part of the spec
        # rubocop:disable Style/CaseEquality
        return false if args[0] === val
        # rubocop:enable Style/CaseEquality
      end
    elsif block
      each do |val|
        return false if block.call(val)
      end
    else
      each do |val|
        return false if val
      end
    end
    true
  end

  def one?(*args, &block)
    count = 0
    if !args.empty?
      each do |val|
        # case equality === is part of the spec
        # rubocop:disable Style/CaseEquality
        count += 1 if args[0] === val
        # rubocop:enable Style/CaseEquality
        return false if count > 1
      end
    elsif block
      each do |val|
        count += 1 if block.call(val)
        return false if count > 1
      end
    else
      each do |val|
        count += 1 if val
        return false if count > 1
      end
    end

    count == 1
  end

  def partition(&block)
    return to_enum :partition unless block

    left = []
    right = []
    each do |val|
      if block.call(val)
        left.push(val)
      else
        right.push(val)
      end
    end
    [left, right]
  end

  def reject(&block)
    return to_enum :reject unless block

    ary = []
    each do |val|
      ary.push(val) unless block.call(val)
    end
    ary
  end

  def reverse_each(&block)
    return to_enum :reverse_each unless block

    ary = to_a
    i = ary.size - 1
    while i >= 0
      block.call(ary[i])
      i -= 1
    end
    self
  end

  def sort(&block)
    map(&:itself).sort(&block)
  end

  def sort_by(&block)
    return to_enum :sort_by unless block

    ary = []
    orig = []
    each_with_index do |e, i|
      orig.push(e)
      ary.push([block.call(e), i])
    end
    ary.sort! if ary.size > 1
    ary.collect { |_e, i| orig[i] }
  end

  def take(size)
    size = size.to_i
    i = size.to_i
    raise ArgumentError, 'attempt to take negative size' if i.negative?

    ary = []
    return ary if i.zero?

    each do |val|
      ary << val
      i -= 1
      break if i.zero?
    end
    ary
  end

  def take_while(&block)
    return to_enum :take_while unless block

    ary = []
    each do |val|
      return ary unless block.call(val)

      ary << val
    end
    ary
  end

  def to_h(&blk)
    h = {}
    if blk
      each do |v|
        v = blk.call(v)
        raise TypeError, "wrong element type #{v.class} (expected Array)" unless v.is_a? Array
        raise ArgumentError, "element has wrong array length (expected 2, was #{v.size})" if v.size != 2

        h[v[0]] = v[1]
      end
    else
      each do |v|
        raise TypeError, "wrong element type #{v.class} (expected Array)" unless v.is_a? Array
        raise ArgumentError, "element has wrong array length (expected 2, was #{v.size})" if v.size != 2

        h[v[0]] = v[1]
      end
    end
    h
  end

  def nil.to_h
    {}
  end

  def uniq(&block)
    hash = {}
    if block
      each do |v|
        hash[block.call(v)] ||= v
      end
    else
      each do |v|
        hash[v] ||= v
      end
    end
    hash.values
  end

  def zip(*arg, &block)
    result = block ? nil : []
    arg = arg.map do |a|
      raise TypeError, "wrong argument type #{a.class} (must respond to :to_a)" unless a.respond_to?(:to_a)

      a.to_a
    end

    i = 0
    each do |val|
      a = []
      a.push(val)
      idx = 0
      while idx < arg.size
        a.push(arg[idx][i])
        idx += 1
      end
      i += 1
      if result.nil?
        block.call(a)
      else
        result.push(a)
      end
    end
    result
  end

  alias collect_concat flat_map
  alias find detect
  alias map collect
  alias member? include?
  alias reduce inject
  alias select find_all
  alias to_a entries
end
