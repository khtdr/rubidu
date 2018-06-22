class Parser
  attr_reader :parser
  def initialize(grammar=nil, &parser)
    @grammar = grammar
    @parser = parser
  end
  def rule(*args)
    @grammar.send(:rule, args) if not @grammar.nil?
  end
  def block(&impl)
    @block_impl = impl
    self
  end
  def parse(input)
    @parser[input]
  end
  def and(other)
    Parser.new(@grammar) do |input|
      node1 = parser[input]
      if node1.failure
        node1
      else
        node2 = other.parser[input[node1.length..-1]]
        if node2.failure
          node2
        else
          children = []
          if node1.type == :and
            children << node1.children
          else
            children << node1
          end
          if node2.type == :and
            children << node2.children
          else
            children << node2
          end
          children = children.flatten#.find_all { |node| node.length > 0 }
          if children.length == 1
            children.first
          else
            Node.new type: :and, length: node1.length+node2.length,
              value: "#{node1.value}#{node2.value}", children: children
          end
        end
      end
    end
  end
  def or(other)
    Parser.new(@grammar) do |input|
      node = parser[input]
      if node.failure
        other.parser[input]
      else
        node
      end
    end
  end
  def maybe
    Parser.new(@grammar) do |input|
      node = parser[input]
      if node.failure
        Node.new type: :maybe
      else
        Node.new type: :maybe, length: node.length, value: node.value, children: [node]
      end
    end
  end
  def plus
    Parser.new(@grammar) do |input|
      index, nodes = 0, []
      while not (node = parser[input[index..-1]]).failure
        index += node.length
        nodes << node
      end
      if index == 0
        Node.new failure: true
      else
        Node.new type: :plus, length: index, value: input[0...index], children: nodes
      end
    end
  end
  def star
    Parser.new(@grammar) do |input|
      index, nodes = 0, []
      while not (node = parser[input[index..-1]]).failure
        index += node.length
        nodes << node
      end
      Node.new type: :star, length: index, value: input[0...index], children: nodes
    end
  end
  def eof
    Parser.new(@grammar) do |input|
      if input == ''
        Node.new type: :eof, length: 0 
      else
        Node.new failure: true
      end
    end
  end
  def char(str)
    Parser.new(@grammar) do |input|
      if input.length > 0 and str.index(input[0]) != nil
        Node.new type: :char, length: 1, value: input[0]
      else
        Node.new failure: true
      end
    end
  end
  def text(str)
    Parser.new(@grammar) do |input|
      if input.start_with? str
        Node.new type: :text, length: str.length, value: str
      else
        Node.new failure: true
      end
    end
  end
  def til(str)
    Parser.new(@grammar) do |input|
      index = input.index str
      if index.nil?
        Node.new failure: true
      else
        Node.new type: :til, length: index, value: input[0...index]
      end
    end
  end
end


#def test_text_parsers
if TEST
  parser = Parser.new.eof.parser
  raise 'expects to fail'     if not parser['input'].failure
  raise 'expects to pass'     if parser[''].failure
  raise 'expects :eof type'   if parser[''].type != :eof
  raise 'expects 0 length'    if parser[''].length != 0
  raise 'expects empty value' if parser[''].value != ''
  raise 'expects 0 children'  if parser[''].children.length != 0

  parser = Parser.new.char('#').parser
  raise 'expects to fail'    if not parser[''].failure
  raise 'expects to fail'    if not parser['abc'].failure
  raise 'expects to fail'    if not parser['a#b#c'].failure
  raise 'expects to pass'    if parser['#'].failure
  raise 'expects to pass'    if parser['##'].failure
  raise 'expects :char type' if parser['#'].type != :char
  raise 'expects 1 length'   if parser['#'].length != 1
  raise 'expects 1 length'   if parser['##'].length != 1
  raise 'expects "#" value'  if parser['#'].value != '#'
  raise 'expects 0 children' if parser['#'].children.length != 0

  parser = Parser.new.char('abc').parser
  raise 'expects to fail'    if not parser[''].failure
  raise 'expects to fail'    if not parser['xyz'].failure
  raise 'expects to fail'    if not parser['#abc'].failure
  raise 'expects to pass'    if parser['a'].failure
  raise 'expects to pass'    if parser['b'].failure
  raise 'expects to pass'    if parser['c'].failure
  raise 'expects :char type' if parser['a'].type != :char
  raise 'expects 1 length'   if parser['a'].length != 1
  raise 'expects 1 length'   if parser['ab'].length != 1
  raise 'expects "a" value'  if parser['a'].value != 'a'
  raise 'expects "b" value'  if parser['b'].value != 'b'
  raise 'expects 0 children' if parser['a'].children.length != 0

  parser = Parser.new.text('abc').parser
  raise 'expects to fail'     if not parser[''].failure
  raise 'expects to fail'     if not parser['a'].failure
  raise 'expects to fail'     if not parser['ab'].failure
  raise 'expects to fail'     if not parser['aabc'].failure
  raise 'expects to pass'     if parser['abc'].failure
  raise 'expects to pass'     if parser['abcabc'].failure
  raise 'expects to pass'     if parser['abcabcabc'].failure
  raise 'expects "abc" value' if parser['abc and more'].value != 'abc'
  raise 'expects :text type'  if parser['abc and more'].type != :text
  raise 'expects 3 length'    if parser['abc and more'].length != 3
  raise 'expects 0 children'  if parser['abc and more'].children.length != 0

  parser = Parser.new.til('end').parser
  raise 'expects to fail'      if not parser[''].failure
  raise 'expects to fail'      if not parser['abc'].failure
  raise 'expects to pass'      if parser['end'].failure
  raise 'expects 0 length'     if parser['end'].length != 0
  raise 'expects to pass'      if parser['til the end'].failure
  raise 'expects 8 length'     if parser['til the end'].length != 8
  raise 'expects :til type'    if parser['til the end'].type != :til
  raise 'expects 0 children'   if parser['til the end'].children.length != 0
  raise 'expects "til the "'   if parser['til the end'].value != "til the "
end

#def test_combinators
if TEST
  parser = Parser.new.text('abc').or(Parser.new.text('xyz')).parser
  raise 'expects to fail on empty' if not parser[''].failure
  raise 'expects to fail on "jkl"' if not parser['jkl'].failure
  raise 'expects to pass on "abc"' if parser['abc'].failure
  raise 'expects to pass on "xyz"' if parser['xyz'].failure
  raise 'expects length 3' if parser['xyz'].length != 3
  raise 'expects type :text' if parser['xyz'].type != :text
  raise 'expects value "xyz"' if parser['xyz'].value != "xyz"
  raise 'expects no children' if parser['xyz'].children.length != 0

  parser = Parser.new.text('abc').and(Parser.new.text('xyz')).parser
  raise 'expects to fail on empty' if not parser[''].failure
  raise 'expects to fail on "abc"' if not parser['abc'].failure
  raise 'expects to fail on "xzy"' if not parser['xzy'].failure
  raise 'expects to pass "abcxyz"' if parser['abcxyz'].failure
  raise 'expects length 6' if parser['abcxyz'].length != 6
  raise 'expects type :text' if parser['abcxyz'].type != :and
  raise 'expects value "xyz"' if parser['abcxyz'].value != "abcxyz"
  raise 'expects a 2 children' if parser['abcxyz'].children.length != 2
  raise 'expects :text children' if parser['abcxyz'].children.first.type != :text
  raise 'expects :text children' if parser['abcxyz'].children.last.type != :text
  parser = Parser.new.text('a')
    .and(Parser.new.text('b'))
    .and(Parser.new.text('c')).parser
  raise 'expects length 3' if parser['abcxyz'].length != 3

  parser = Parser.new.text('abc').maybe.parser
  raise 'expects to pass on empty' if parser[''].failure
  raise 'expects to pass on "xyz"' if parser['xyz'].failure
  raise 'expects length  0 on "xyz"' if parser['xyz'].length != 0
  raise 'expects to pass on "abc"' if parser['abc'].failure
  raise 'expects length 3 on "abc"' if parser['abc'].length != 3
  raise 'expects :maybe on "abc"' if parser['abc'].type != :maybe
  raise 'expects to match value "abc"' if parser['abc'].value != 'abc'

  parser = Parser.new.text('abc').star.parser
  raise 'expects to pass on empty' if parser[''].failure
  raise 'expects to fail on "xyz"' if parser['xyz'].failure
  raise 'expects length  0 on "xyz"' if parser['xyz'].length != 0
  raise 'expects to pass on "abc"' if parser['abc'].failure
  raise 'expects length 3 on "abc"' if parser['abc'].length != 3
  raise 'expects :star on "abc"' if parser['abc'].type != :star
  raise 'expects to match value "abc"' if parser['abc'].value != 'abc'
  raise 'expects to pass on "abcabcabcabc"' if parser['abcabcabcabc'].failure
  raise 'expects length 3 on "abc"' if parser['abcabcabcabc'].length != 12
  raise 'expects :star on "abc"' if parser['abcabcabcabc'].type != :star
  raise 'expects to match value "abc"' if parser['abcabcabcabc'].value != 'abcabcabcabc'

  parser = Parser.new.text('abc').plus.parser
  raise 'expects to fail on empty' unless parser[''].failure
  raise 'expects to fail on "xyz"' unless parser['xyz'].failure
  raise 'expects length  0 on "xyz"' if parser['xyz'].length != 0
  raise 'expects to pass on "abc"' if parser['abc'].failure
  raise 'expects length 3 on "abc"' if parser['abc'].length != 3
  raise 'expects :plus on "abc"' if parser['abc'].type != :plus
  raise 'expects to match value "abc"' if parser['abc'].value != 'abc'
  raise 'expects to pass on "abcabcabcabc"' if parser['abcabcabcabc'].failure
  raise 'expects length 3 on "abc"' if parser['abcabcabcabc'].length != 12
  raise 'expects :plus on "abc"' if parser['abcabcabcabc'].type != :plus
  raise 'expects to match value "abc"' if parser['abcabcabcabc'].value != 'abcabcabcabc'
end

