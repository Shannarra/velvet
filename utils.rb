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

    match?(/[\d_]/)
  end

  def error!
    "[ERROR]: #{self}"
  end
end

def pretty_print_tree(root, indent = '', is_last: true)
  marker = is_last ? '└───' : '├───'

  value = nil
  if root.is_a?(Syntax::SyntaxTree)
    root = root.root
  elsif root.is_a? Array
    if root.is_a?(Syntax::Token)
      value = root.value
    else
      indent += is_last ? '    ' : '│   '

      return root.each do |item|
        pretty_print_tree(item, indent)
      end
    end
  else
    value = root&.value
  end

  if root
    out = "#{indent}#{marker}#{root&.kind}"
    out += " \"#{value}\"" if value

    puts out
  end

  indent += is_last ? '    ' : '│   '
  last_child = root.children[-1] if root

  root&.children do |child|
    pretty_print_tree(child, indent, is_last: child == last_child)
  end
end
