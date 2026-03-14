# coding: utf-8
# frozen_string_literal: true

require 'pry'

require_relative 'utils'
require_relative 'syntax/base'
require_relative 'syntax/evaluation'

def pretty_print_tree(root, indent = '', is_last: true)
  marker = is_last ? '└───' : '├───'

  print "#{indent}#{marker}#{root.kind}"

  print " #{root.value}" if root.is_a?(Syntax::Token) && !root.value.nil?
  puts ''

  indent += is_last ? '    ' : '│   '
  last_child = root.children[-1]

  root.children do |child|
    pretty_print_tree(child, indent, is_last: child == last_child)
  end
end

def evaluate_expression(tree, variables = {})
  evaluator = Syntax::Evaluator.new(tree.root, variables)
  res = evaluator.eval!

  puts res
rescue RuntimeError
  print_diagnostics(evaluator)
end

def print_diagnostics(container)
  container.diagnostics.each do |diagnostic|
    eputs diagnostic
  end
end

def repl_loop(show_tree)
  variables = {}

  loop do
    print '> '
    line = gets.strip
    return if line.empty?

    case line
    when '#clear', '#c', '#cls'
      system('clear')
      next
    when '#printTree', '#print', '#p'
      show_tree = !show_tree
      puts "#{(!show_tree && 'Not ') || ''}Showing Tree"
      next
    when '#exit', '#e', '#quit', '#q'
      return
    end

    tree = Syntax::SyntaxTree.parse(line)

    pretty_print_tree(tree.root) if show_tree

    if tree.diagnostics.flatten.any?
      print_diagnostics(tree)
    else
      evaluate_expression(tree, variables)
    end
  end
end

def compile_and_execute(file)
  error! "File #{file} does not exist." unless File.exist? file

  variables = {}
  contents = File.readlines file

  tree = Syntax::SyntaxTree.parse(contents)

  if tree.diagnostics.flatten.any?
    print_diagnostics(tree)
  else
    evaluate_expression(tree, variables)
  end

  exit
end

def main
  debug_show_tree = false
  ARGV.each do |x|
    case x
    when '--showTree', '-st', '--debugPrint', '-dp' then debug_show_tree = true
    else
      compile_and_execute ARGV.first
      # wputs "Unrecognized cli argument \"#{x}\". Running with default configuration."
    end
  end.clear

  repl_loop(debug_show_tree)
end

main
