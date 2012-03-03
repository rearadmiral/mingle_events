module MingleEvents
  module Xml

    class Element
      attr_reader :node, :namespaces
      def initialize(node, namespaces)
        @node = node
        @namespaces = namespaces
      end

      def nil?
        @node.nil?
      end

      ["inner_text", "optional_inner_text", "select", "select_all", "attr", "children", "tag_name", "raw_xml", "attributes", "to_hash"].each do |method|
        self.class_eval(%{def #{method}(*args, &block)  Xml.#{method}(self, *args); end})
      end

      alias :[] :attr
    end


    module_function

    def parse(str, namespaces={})
      Element.new(Nokogiri::XML(str), namespaces)
    end

    def inner_text(element, xpath=nil)
      return inner_text(select(element, xpath)) if xpath
      return nil if attr(element, "nil") && attr(element, "nil") == "true"
      element.node.inner_text
    end

    def optional_inner_text(parent_element, xpath)
      element = select(parent_element, xpath)
      element.node.nil? ? nil : element.inner_text
    end

    def select(element, xpath)
      Element.new(element.node.at(xpath, element.namespaces), element.namespaces)
    end

    def select_all(element, xpath)
      element.node.search(xpath, element.namespaces).map { |n| Element.new(n, element.namespaces) }
    end

    def attr(element, attr_name)
      raise 'element selection is empty!' if element.nil?
      element.node[attr_name]
    end

    def children(element)
      element.node.children.select { |e| e.is_a?(Nokogiri::XML::Element) }.map { |n| Element.new(n, element.namespaces) }
    end

    def tag_name(element)
      element.node.name
    end

    def raw_xml(element)
      patching_namespaces(element.node).to_s
    end

    def attributes(element)
      element.node.attribute_nodes.inject({}) do |memo, a|
        memo[a.name] = a.value
        memo
      end
    end

    def to_hash(element, hash={})
      hash_for_element = (hash[tag_name(element).to_sym] ||= {})

      attributes(element).each do |name, value|
        hash_for_element[name.to_sym] = value
      end

      children(element).each do |child|
        if children(child).any?
          to_hash(child, hash_for_element)
        else
          hash_for_element[tag_name(child).to_sym] = inner_text(child)
        end
      end

      hash
    end

    def patching_namespaces(node)
      ns_scopes = node.namespace_scopes
      return node if ns_scopes.empty?

      result = node.clone
      ns_scopes.each do |ns|
        result.add_namespace_definition(ns.prefix, ns.href)
      end
      result
    end
  end
end
