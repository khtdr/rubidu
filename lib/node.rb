class Node
  attr_reader :failure, :length, :type, :value, :children
  def initialize(failure:false, length:0, type:nil, value:'', children:[], evaluator:nil)
    @failure, @length, @type, @value, @children, @evaluator = failure, length, type, value, children, evaluator
  end
  def eval
    @evaluator.call(self) unless @evaluator == nil
  end
  def child
    @children[0]
  end
  def to_s
    require 'pp'
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

if TEST
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

