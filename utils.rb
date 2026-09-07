# frozen_string_literal: true

module Kernel
  # https://stackoverflow.com/a/11455651/11542917
  def enum(values)
    Module.new do |mod|
      values.each_with_index { |v, _i| mod.const_set(v, v.to_s) }

      def mod.inspect
        "#{name} {#{constants.join(', ')}}"
      end
    end
  end

  def wputs(text)
    puts "[WARN]: #{text}"
  end

  def eputs(text)
    puts "[ERROR]: #{text}"
  end

  def assert!(condition, message = nil)
    message ||= "Expectation not met: #{condition}"

    raise message.error! unless condition
  end
end

class String
  def letter?
    match?(/[[:alpha:]]/)
  end

  def numeric?
    # for some reason /[0-9]/ doesn't match numbers ffs
    (match?(/[[:digit:]]/) && match?(/[1-9]/)) || self == '0'
  end

  def error!
    "[ERROR]: #{self}"
  end
end

def pretty_print_tree(root, indent = '', is_last: true)
  return if root.nil?
  return if root.is_a?(String)

  marker = is_last ? '└───' : '├───'

  root = root.root if root.is_a?(Syntax::SyntaxTree)

  # when the sub-tree is an array - print all items as children
  if root.is_a?(Array)
    last_item = root.last

    root.each do |item|
      pretty_print_tree item, "#{indent}│   ", is_last: item == last_item
    end

    return
  end

  print "#{indent}#{marker}#{root.kind}"

  # special print for different root values
  if root.is_a?(Syntax::Token) && !root.value.nil?
    print case root.kind
          when Syntax::SyntaxKind::StringToken
            " \"#{root.value}\""
          else
            " #{root.value}"
          end
  end

  puts

  indent += is_last ? '    ' : '│   '
  last_child = root.children[-1]

  root.children do |child|
    pretty_print_tree(child, indent, is_last: child == last_child)
  end
end
