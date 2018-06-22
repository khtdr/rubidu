TEST=ENV['TEST']||false unless defined? TEST

require_relative './lib/node.rb'
require_relative './lib/parser.rb'
require_relative './lib/grammar_parser.rb'
require_relative './lib/bnf_parser.rb'

def help
  puts "Usage: cat program.txt | #{$0} -g grammar_file.rbd"
  puts "Options:"
  puts "  -v Shows the version"
  puts "  -h Shows this message"
end

vflag = ! $*.index("-v").nil?
hflag = ! $*.index("-h").nil?
if vflag then puts "1.0.0" end
if hflag then help end

exit if vflag or hflag

gflag = ! $*.index("-g").nil?
unless gflag
  help
  exit
end
grammar = File.read $*[gflag + 1]
input = $stdin.read
BnfParser.new.parse(grammar).build.eval(input)
