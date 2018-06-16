require 'pp'
class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end

  def bg_black;       "\e[40m#{self}\e[0m" end
  def bg_red;         "\e[41m#{self}\e[0m" end
  def bg_green;       "\e[42m#{self}\e[0m" end
  def bg_brown;       "\e[43m#{self}\e[0m" end
  def bg_blue;        "\e[44m#{self}\e[0m" end
  def bg_magenta;     "\e[45m#{self}\e[0m" end
  def bg_cyan;        "\e[46m#{self}\e[0m" end
  def bg_gray;        "\e[47m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
  def blink;          "\e[5m#{self}\e[25m" end
  def reverse_color;  "\e[7m#{self}\e[27m" end
end

class Node
  attr_reader :failure, :length, :type, :value, :children
  def initialize(failure:false, length:0, type:nil, value:'', children:[], evaluator:nil)
    @failure, @length, @type, @value, @children, @evaluator = failure, length, type, value, children, evaluator
  end
  def eval
    #self.instance_eval &@evaluator unless @evaluator == nil
    @evaluator.call(self) unless @evaluator == nil
  end
  def child
    @children[0]
  end
  def to_s
    return PP.pp to_hash, ""
  end
  def to_hash
    if @failure
      {:error=>true}
    elsif @children.length == 0
      {:type=>@type, :length=>@length, :value=>@value}
    else
      {:type=>@type, :length=>@length, :value=>@value, :children=> @children.map {|n|n.to_hash} }
    end
  end
end

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

class GrammarParser < Parser
  attr_reader :rules
  def initialize &block
    @rules = {}
    parser = Parser.new(self) do |input|
      instance_eval &block
    end
    parser.parser.call()
  end
  def rule(name, node_eval=nil, &body_def)
    if body_def.nil?
      @rules.fetch(name.to_s.downcase.to_sym) { raise "no such rule: #{name}"}
    else
      @rules[name.to_s.downcase.to_sym] = Parser.new(self) do |input|
        node = body_def.call.parser[input]
        if node.failure
          node
        else
          Node.new type: name.to_s.downcase.to_sym, value: node.value,
            length: node.length, children: [node], evaluator: node_eval
        end
      end
    end
  end
  def root_rule(name)
    @root = name
    self
  end
  def parse(input)
    raise 'must call `root_rule` first' unless @root
    parse_rule(@root, input)
  end
  def parse_rule(name, input)
    rule(name).parse(input)
  end
end

class BnfParser
  attr_reader :ast
  def initialize
    @parser = GrammarParser.new {
      rule(:root, Proc.new { |node|
        ## root: *(ws assignment ws).
        node.child.child.children.map { |node|
          _1, assignment, _2 = node.children
          assignment.eval
        }
      }) { rule(:ws).and(rule(:assignment)).and(rule(:ws)).star.and(eof) }
      rule(:assignment, Proc.new { |node|
        ## assignment: identifier ws ":" ws +term ?block "." .
        identifier = node.child.children[0].value
        terms = node.child.children[4]
        block = node.child.children[5]
        terms.children.map { |term| term.eval }
      }) { rule(:identifier).and(rule(:ws)).and(text(':').and(rule(:ws))).and(rule(:term).plus).and(rule(:block).maybe).and(text('.')) }
      ## identifier : +'-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890'.
      rule(:identifier) { char('-ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890').plus }
      ## ws : *' \t\r\n'.
      rule(:ws) { char(" \t\r\n").star }
      ## block: ?("{\n" >"\n}" "\n}" ws).
      rule(:block) { text("{\n").and(til("\n}")).and(text("\n}")).and(rule(:ws)).maybe }
      ## term : factor ?"!" ws.
      rule(:term, Proc.new { |node| 
        factor, take = node.child.children
        factor.eval
      }) { rule(:factor).and(text('!').maybe).and(rule(:ws)) }
      ## factor: ?'*+?' [identifier string chars until seq any].
      rule(:factor, Proc.new { |node|
        quantity, factor = node.child.children
        factor.eval
      }) { char('*+?').maybe.and(rule(:identifier).or(rule(:string)).or(rule(:chars)).or(rule(:until)).or(rule(:seq)).or(rule(:any))) }
      ## string: '"' >'"' '"'.
      rule(:string, Proc.new { |node|
        str = node.child.children[1].value
        text(str)
      }) { text('"').and(til('"')).and(text('"')) }
      ## chars : "'" >"'" "'".
      rule(:chars, Proc.new { |node|
        str = node.child.children[1].value
        char(str)
      }) { text("'").and(til("'")).and(text("'")) }
      ## until:">"[string chars].
      rule(:until, Proc.new { |node|
        str = node.child.children[1].value
        til(str)
      }) { text(">").and(rule(:string).or(rule(:chars))) }
      ## seq: "(" ws +term ")".
      rule(:seq) { text("(").and(rule(:ws)).and(rule(:term).plus).and(text(")")) }
      ## any: "[" ws +term "]".
      rule(:any) { text("[").and(rule(:ws)).and(rule(:term).plus).and(text("]")) }
    }
    self
  end
  def parse(grammar)
    @ast = @parser.root_rule(:root).parse(grammar)
    self
  end
  def build
    @ast.eval
    self
  end
  def eval(input)
  end
end

def test_nodes
  node = Node.new
  raise 'new node is not a failure' if node.failure
  raise 'new node has a nil type'   if node.type != nil
  raise 'new node has no length'    if node.length != 0
  raise 'new node has no value'     if node.value != ''
  raise 'new node has no children'  if node.children.length != 0

  node = Node.new type: :type, length: 1
  raise 'always node is not a failure' if node.failure
  raise 'always node has a type'       if node.type != :type
  raise 'always node has length of 1'  if node.length != 1
  raise 'always node has no value'     if node.value != ''
  raise 'always node has no children'  if node.children.length != 0

  node = Node.new type: :type, length: 4, value: 'x', children: [:child]
  raise 'always node is not a failure' if node.failure
  raise 'always node has a type'       if node.type != :type
  raise 'always node has length of 1'  if node.length != 4
  raise 'always node has no value'     if node.value != 'x'
  raise 'always node has no children'  if node.children.length != 1

  node = Node.new failure: true
  raise 'never node is a failure' if not node.failure
  begin
    node.length
    raise 'expected to raise invalid node exception'
  rescue RuntimeError => err
    raise 'expected failure exception' unless err.message.match 'invalid node'
  end
end

def test_text_parsers
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

def test_combinators
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

def test_grammar
  grammar = GrammarParser.new do
    rule(:center) { text('cen').and(rule(:center).maybe).and(text('ter')) }
  end
  rules = grammar.rules
  raise 'expects to pass' if rules[:center].parser['center'].failure
  raise "inner pump 1" if rules[:center].parser['center'].value != "center"
  raise "inner pump 2" if rules[:center].parser['cencenterter'].length != 12
  raise 'expected :center type' if grammar.parse_rule(:center, "center").type != :center
  begin
    grammar.parse('blah')
    raise 'expected to raise root_rule exception'
  rescue RuntimeError => err
    raise 'expected failure exception' unless err.message.match 'root_rule'
  end
  grammar.root_rule(:center)
  raise 'expects to fail' if not grammar.parse('blah').failure
  raise 'expects to pass' if grammar.parse('center').failure
end

def test_bnf_grammar
  parser = BnfParser.new
  raise 'should accept' if parser.parse('jojoeyey:?blah    +>"blah"  . lksjfalsdkf:+\'j\'.joey:was *here.').ast.failure
  raise 'should accept' if parser.parse('rule:("rule" rule).').ast.failure
  raise 'should accept' if parser.parse('  rule: ("rule" ["a" "b" "c"]).').ast.failure
  raise 'should accept' if parser.parse('jojoeyey :?blah +>"blah".lksjfalsdkf :+\'j\'.joey   :    was *here .   ').ast.failure
  raise 'should accept' if parser.parse('jojoeyey :?blah +>"blah"   .   lksjfalsdkf :+\'j\'.joey   :    was *here .   ').ast.failure
  raise 'should accept' if parser.parse('rule  :("rule" rule).').ast.failure
  raise 'should accept' if parser.parse('rule:("rule"["a""b""c"]).').ast.failure
  raise 'should accept' if parser.parse('rule: ("rule" ["a" "b" "c"]).').ast.failure
  raise 'should accept' if parser.parse('rule1:"rule1".rule2:"rule2".').ast.failure
  raise 'should accept' if parser.parse('rule:("rule" ["a" "b" "c"]). rule2:("rule"["a" "b" "c"]).').ast.failure
  raise 'should accept' if parser.parse('rule:("rule" ["a" "b" "c"])    . rule2:("rule"["a""b""c"]).').ast.failure
  raise 'should accept' if parser.parse(' rule : ( "rule" [ "a" "b" "c" ] ) .rule2:("rule"["a" "b" "c"]).').ast.failure
  raise 'should accept' if parser.parse("a:'a'{\n code block \n} .").ast.failure
  raise 'should accept' if parser.parse('Joey: "joey"! ?("was" "here").').ast.type != :root
  puts BnfParser.new.parse('Joey: "joey"! ?("was" "here").').build.eval "joey"
end

# $> ruby ./rubidu.rb test_
if self.to_s == 'main'
  self.private_methods.each do |name|
    test_fn = name.match /^#{ARGV.first}/
    next unless test_fn
    print "#{name}".blue
    $stdout.flush
    self.send(name)
    print " ✓\n".green.bold
    $stdout.flush
  end if ARGV.length == 1 and ARGV.first.match /^test_/

  gflag = $*.index("-g")
  unless gflag.nil?
    grammar = File.read $*[gflag + 1]
    input = $stdin.read
    BnfParser.new.parse(grammar).eval(input)
  end
end

