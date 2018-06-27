VERSION="1.0.1"
TEST=!$*.index("--test").nil? unless defined? TEST

require_relative './lib/node.rb'
require_relative './lib/parser.rb'
require_relative './lib/grammar_parser.rb'
require_relative './lib/bnf_parser.rb'

exit if TEST

def help
  puts "Usage:"
  puts "  #{$0} -g grammar.txt -p program.txt"
  puts "  cat program.txt | #{$0} -g grammar.txt"
  puts "Options:"
  puts "  -v Shows the version"
  puts "  -h Shows this message"
  puts "  --test Runs the test suite"
  puts "Version:"
  puts "  #{VERSION}"
end

vflag = ! $*.index("-v").nil?
hflag = ! $*.index("-h").nil?
if vflag then puts VERSION end
if hflag then help end

exit if vflag or hflag

gflag = ! $*.index("-g").nil?
unless gflag
  help
  exit
end
grammar = File.read $*[gflag + 1]

pflag = ! $*.index("-p").nil?
if pflag
  input = File.read $*[pflag + 1]
else
  input = $stdin.read
end

BnfParser.new.parse(grammar).build.eval(input)
