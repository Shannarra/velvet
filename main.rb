# coding: utf-8
# frozen_string_literal: true

require 'pry'

require_relative 'utils'
require_relative 'syntax/base'
require_relative 'syntax/evaluation'

def print_help
  puts <<~TEXT
    Velvet usage:

    ruby main.rb
         --showTree, -st, --debugPrint, -dp                 Shows the AST generated from your expression/file.
         -h, --help                                         Prints this message
         -f, --file [FILENAME]                              Provide a flie to be evaluated. Starts REPL if not provided.
  TEXT
end

def evaluate_expression(tree)
  evaluator = Syntax::Evaluator.new(tree.root, Syntax::GlobalScope.new)

  # print the evaluation of each line:

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
      tree.root.children.each do |sub|
        evaluate_expression(sub, variables)
      end
    end
  end
end

def compile_and_execute(file, show_tree)
  error! "File #{file} does not exist." unless File.exist? file

  variables = {}
  contents = File.read file

  tree = Syntax::SyntaxTree.parse(contents)

  if tree.diagnostics.flatten.any?
    print_diagnostics(tree)
  else
    Syntax::Evaluator.eval_tree! tree, variables
  end

  pretty_print_tree(tree.root) if show_tree

  exit
end

def main
  debug_show_tree = false
  ARGV.each_with_index do |x, idx|
    case x
    when '--showTree', '-st', '--debugPrint', '-dp' then debug_show_tree = true
    when '-h', '--help' then print_help
    when '-f', '--file'
      file = ARGV[idx + 1]

      unless file
        eputs 'Provide a file to the -f|--file option!'
        print_help
        exit(1)
      end

      compile_and_execute file, debug_show_tree
    else
      wputs "Unrecognized cli argument \"#{x}\". Running with default configuration."
    end
  end.clear

  repl_loop(debug_show_tree)
end

main
