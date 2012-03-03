require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))

module MingleEvents
  class XmlTest < Test::Unit::TestCase
    def test_get_inner_text
      assert_equal "s", Xml.parse("<a><b>s</b></a>").inner_text
      assert_equal "s", Xml.parse("<a><b>s</b></a>").inner_text("b")
    end

    def test_optional_inner_text
      assert_equal nil, Xml.parse("<a></a>").optional_inner_text("b")
      assert_equal 's', Xml.parse("<a><b>s</b></a>").optional_inner_text("b")
    end

    def test_select_return_element_match_path
      assert_equal "s", Xml.parse("<a><b>s</b><b>t</b></a>").select('a/b').inner_text
    end

    def test_select_all_return_all_elements_match_path
      assert_equal ["s", "t"], Xml.parse("<a><b>s</b><b>t</b></a>").select_all('a/b').map(&:inner_text)
    end

    def test_get_attribute_from_xml_element
      assert_equal "s", Xml.parse('<a t="s"></a>').select('a').attr("t")
    end

    def test_get_children
      assert_equal ['s', 't', 'u'], Xml.parse(%{<a><s/> <t/> <u/> </a>}).select('a').children.map(&:tag_name)
    end

    def test_serialize_to_xml
      assert_equal_ignore_spaces "<b>s</b>", Xml.parse("<a><b>s</b></a>").select("a/b").raw_xml
    end

    def test_get_all_attributes
      assert_equal({'x' => 's', 'y' => 't', 'z' => 'u'}, Xml.parse('<a x="s" y="t" z="u" />').select('a').attributes)
    end

    def test_element_to_hash
      assert_equal({:a => {:x => "s", :b => { :y => "t", :e => "0"}, :c => "1", :d => nil}}, Xml.parse('<a x="s"> <b y="t"> <e>0</e> </b> <c>1</c> <d nil="true" /> </a>').select("a").to_hash)
    end

    def test_select_with_namespace
      xml_with_ns = '<a xmlns="http://www.w3.org/2005/Atom" xmlns:foo="http://www.foo.com"> <foo:b>s</foo:b> </a>'
      ns = {'atom' => "http://www.w3.org/2005/Atom", 'foo' => "http://www.foo.com"}
      assert_equal "s", Xml.parse(xml_with_ns, ns).select("/atom:a").inner_text.strip
      assert_equal "s", Xml.parse(xml_with_ns, ns).select("/atom:a/foo:b").inner_text
      assert_equal "s", Xml.parse(xml_with_ns, ns).select("/atom:a").select("./foo:b").inner_text
      assert_equal "s", Xml.parse(xml_with_ns, ns).select("./atom:a").select("./foo:b").inner_text
    end

    def test_serialize_to_xml_with_namespace
      xml_with_ns = %{
        <a xmlns="http://www.foo.com" xmlns:bar="http://www.bar.com">
           <b>
             <bar:c>
                 s
             </bar:c>
           </b>
        </a>
      }
      ns = {'foo' => "http://www.foo.com", 'bar' => "http://www.bar.com"}
      serialized = Xml.parse(xml_with_ns, ns).select("/foo:a/foo:b").raw_xml
      assert_equal_ignore_spaces(%{
          <b xmlns="http://www.foo.com" xmlns:bar="http://www.bar.com">
             <bar:c>
               s
             </bar:c>
          </b>
      }, serialized)
      assert_equal 's',  Xml.parse(serialized, ns).select("/foo:b/bar:c").inner_text.strip
    end

    private

    def assert_equal_ignore_spaces(expected, actual)
      assert_equal(expected.gsub(/[ |\n]/, ''), actual.gsub(/[ |\n]/, ''))
    end
  end
end
