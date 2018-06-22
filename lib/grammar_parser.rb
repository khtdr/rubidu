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


if TEST
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
