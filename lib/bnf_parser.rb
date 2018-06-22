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
        ands = terms.children.map { |term| term.eval }
        i = 0
        until i > ands.length - 2
          ands[i].and ands[i+1]
          i += 1
        end
        ands
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
      rule(:seq, Proc.new {|node|
        terms = node.child.children[2].children
        ands = terms.map { |term| term.eval }
        i = 0
        until i > ands.length - 2
          ands[i].and ands[i+1]
          i += 1
        end
        ands
      }) { text("(").and(rule(:ws)).and(rule(:term).plus).and(text(")")) }
      ## any: "[" ws +term "]".
      rule(:any, Proc.new { |node|
        terms = node.child.children[2].children
        ors = terms.map { |term| term.eval }
        i = 0
        until i > ands.length - 2
          ors[i].or ors[i+1]
          i += 1
        end
        ors
      }) { text("[").and(rule(:ws)).and(rule(:term).plus).and(text("]")) }
    }
    self
  end
  def parse(grammar)
    @ast = @parser.root_rule(:root).parse(grammar)
    self
  end
  def build
    @gen = @ast.eval
    self
  end
  def eval(input)
    puts @gen.inspect
  end
end

if TEST
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
  puts BnfParser.new.parse('Joey: "joey"! ?("was" "here").').build.eval("joey")
end
