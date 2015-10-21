module MatchNodes
  class Matcher
    def css_select root, selector
      HTML::Selector.new(selector).select(root)
    end

    def initialize expected_nodes
      @expected_nodes = expected_nodes
    end

    def matches? text
      @text = text
      root_node = HTML::Document.new(text, false, false).root
      matches_nodes? [root_node], @expected_nodes
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

got #{@failure_nodes.size} nodes :
#{@failure_nodes.join "\n"}#{failure_attribute_message}"
    end

    def description
      "contain html nodes #{@expected_nodes}"
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
        return @failure_attribute_value.present?
      else
        @failure_attribute_value = nodes[0].attributes[name.to_s].to_s
        return @failure_attribute_value == expected.to_s
      end
    end

    def matches_nodes? nodes, expected, path=''
      @failure_attribute_name     = nil
      @failure_attribute_value    = nil
      @failure_attribute_expected = nil
      @failure_nodes              = nodes
      @failure_selector           = path
      @failure_expected           = expected

      if expected.is_a? Hash
        return false unless nodes.present?
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
              return false unless matches_nodes?(new_nodes, value, [path, key].join(" ").strip)
            end
          end
        end
      elsif expected.is_a? Fixnum
        return false unless expected == nodes.size
      elsif expected.is_a? Array
        return false unless expected.size == nodes.size
        return false unless nodes.zip(expected).inject(true) { |truth, pair|
          truth && matches_nodes?([pair[0]], pair[1], path)
        }
      else
        return false unless matches_node?(nodes[0], expected, path)
      end
      true
    end

    def matches_node? node, expected, path
      if expected == true
        node.present?
      elsif (expected == :debug)
        puts "node at selector #{path.inspect}"
        puts node
        true
      elsif (expected == false) || (expected.nil?)
        node.nil?
      elsif expected.is_a? String
        txt = node_to_txt(node)
        node.present? && (txt == expected)
      elsif expected.is_a? Regexp
        txt = node_to_txt(node)
        node.present? && txt.match(expected)
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
