require "yaml"
require "nokogiri"

module MatchNodes
  class Matcher
    def css_select root, selector
      root.css selector
    end

    def initialize expected_nodes
      @expected_nodes = expected_nodes
    end

    def matches? text
      @text = text
      root_node = Nokogiri::HTML(text)
      matches_nodes? [root_node], @expected_nodes
    end

    def failure_text_message
      return nil if @failure_text.nil?
      "

expected text was
=================
#{@failure_expected}

  actual text was
=================
#{@failure_text}
"
    end

    def failure_attribute_message
      return nil if @failure_attribute_name.nil?
      "

expected attribute #{@failure_attribute_name.inspect}
             to be #{@failure_attribute_expected.inspect}
               got #{@failure_attribute_value.inspect}
"
    end

    def failure_message
      "selector #{@failure_selector.split(/ +/).to_yaml}
didn't match expected nodes
#{@failure_expected.to_yaml}
#{if @failure_expected.is_a?(Array) ; "\nexpected #{@failure_expected.size} nodes\n" ; end}
got #{@failure_nodes.size} nodes :
#{@failure_nodes.to_a.map {|n| n.to_html }.join "\n"}#{failure_attribute_message}#{failure_text_message}"
    end

    def description
      "contain html nodes #{@expected_nodes}"
    end

    def present? thing
      return !thing.empty? if thing.respond_to?(:empty)
      thing != nil && thing != "" && thing != [] && thing != {}
    end

    def matches_attribute? nodes, name, expected, path
      @failure_attribute_name = name
      @failure_attribute_expected = expected
      if name == :innerHTML
        return matches_nodes?(nodes, expected, path)
      elsif name == :innerText
        @failure_attribute_value = inner_text(nodes[0])
        return @failure_attribute_value == expected.to_s
      elsif expected == false
        @failure_attribute_value = nodes[0].attributes[name.to_s].to_s
        return @failure_attribute_value.blank?
      elsif expected == true
        @failure_attribute_value = nodes[0].attributes[name.to_s].to_s
        return present? @failure_attribute_value
      elsif expected.is_a? Regexp
        @failure_attribute_value = nodes[0].attributes[name.to_s].to_s
        return @failure_attribute_value.match(expected)
      else
        @failure_attribute_value = nodes[0].attributes[name.to_s].to_s
        return @failure_attribute_value == expected.to_s
      end
    end

    def path_with_index str, i
      i ? [str, i].join("#") : str
    end

    def matches_nodes? nodes, expected, path='', array_index=nil
      @failure_text               = nil
      @failure_attribute_name     = nil
      @failure_attribute_value    = nil
      @failure_attribute_expected = nil
      @failure_nodes              = nodes
      @failure_selector           = path_with_index(path, array_index)
      @failure_expected           = expected
      @failure_index              = array_index

      if expected.is_a? Hash
        return false unless present?(nodes)
        raise "missing node: #{nodes.inspect} at path #{path}, expected #{expected}" if nodes[0] == nil
        expected.each do |key, value|
          if key.is_a? Symbol
            return false unless matches_attribute?(nodes, key, value, path)
          else
            new_nodes = css_select(nodes[0], key)
            if value == :debug
              puts "at selector #{path.inspect}"
              puts "selecting #{key.inspect}"
              puts "found #{new_nodes.size} nodes :"
              new_nodes.each { |node|
                puts node
              }
            else
              return false unless matches_nodes?(new_nodes, value, [path_with_index(path, array_index), key].join(" ").strip)
            end
          end
        end
      elsif expected.is_a? Fixnum
        return false unless expected == nodes.size
      elsif expected.is_a? Array
        return false unless expected.size == nodes.size
        i = -1
        return false unless nodes.zip(expected).inject(true) { |truth, pair|
          i +=1
          truth && matches_nodes?([pair[0]], pair[1], path, i)
        }
      else
        return false unless matches_node?(nodes[0], expected, path)
      end
      true
    end

    def matches_node? node, expected, path
      if expected == true
        present? node
      elsif (expected == :debug)
        puts "node at selector #{path.inspect}"
        puts node
        true
      elsif (expected == false) || (expected.nil?)
        node.nil?
      elsif expected.is_a? String
        @failure_text = node_to_txt(node)
        present?(node) && (@failure_text == expected)
      elsif expected.is_a? Regexp
        @failure_text = node_to_txt(node)
        present?(node) && @failure_text.match(expected)
      else
        raise "don't know how to compare #{expected.inspect} to #{node.inspect}\nselector was #{path.inspect}"
      end
    end

    def node_to_txt html_node
      self.class.node_to_txt html_node
    end

    def self.node_to_txt html_node
      return "" if html_node.nil?
      s = html_node.children.map(&:to_s).join
      s = s.gsub(/<[^>]+>/, " ").gsub(/ +/, " ").gsub(/( *\n *)+/, "\n").strip
    end

    def inner_text html_node
      node_to_txt(html_node).gsub(/\s+/, ' ')
    end
  end
end
