TEST=true

class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end
  def bold;           "\e[1m#{self}\e[22m" end
end

# $> ruby ./test.rb
suite = [
  './lib/node.rb',
  './lib/parser.rb',
  './lib/grammar_parser.rb',
  './lib/bnf_parser.rb',
]
suite.each {|file_name|
  print "#{file_name}".blue
  $stdout.flush
  require_relative file_name
  print " ✓\n".green.bold
  $stdout.flush
}
