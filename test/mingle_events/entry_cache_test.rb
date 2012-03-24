require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))

module MingleEvents
  class EntryCacheTest < Test::Unit::TestCase
    
    def setup
      @entry_cache = EntryCache.new("/tmp/foo")
      @entry_cache.clear
    end
    
    def test_stores_first_entry_under_root
      fetched_entry = entry(1)
      @entry_cache.write(fetched_entry, nil)
      @entry_cache.update_current_state(fetched_entry, fetched_entry)
      @entry_cache.flush
      assert_equal [entry(1)], @entry_cache.all_entries.to_a
      assert_equal entry(1), @entry_cache.first
      assert_equal entry(1), @entry_cache.latest
    end

    def test_store_multiple_entries
      @entry_cache.write(entry(3), nil)
      @entry_cache.write(entry(2), entry(3))
      @entry_cache.write(entry(1), entry(2))
      @entry_cache.update_current_state(entry(1), entry(3))
      @entry_cache.flush
      assert_equal [entry(1), entry(2), entry(3)], @entry_cache.all_entries.to_a
    end

    def test_store_multiple_entries_multiple_times
      @entry_cache.write(entry(3), nil)
      @entry_cache.write(entry(2), entry(3))
      @entry_cache.write(entry(1), entry(2))
      @entry_cache.update_current_state(entry(1), entry(3))
      @entry_cache.flush

      @entry_cache.write(entry(6), nil)
      @entry_cache.write(entry(5), entry(6))
      @entry_cache.write(entry(4), entry(5))
      @entry_cache.write(entry(3), entry(4))
      @entry_cache.update_current_state(entry(3), entry(6))
      @entry_cache.flush

      assert_equal((1..6).map { |id| entry(id) }, @entry_cache.all_entries.to_a)
    end
    
    private
    
    def entry(id)
      element_xml_text = %{
        <entry xmlns="http://www.w3.org/2005/Atom">
          <id>https://mingle.example.com/projects/mingle/events/index/#{id}</id>
          <title>Page Special:HeaderActions changed</title>
          <updated>2011-02-03T08:12:42Z</updated>
          <author>
            <name>Sammy Soso</name>
            <email>sammy@example.com</email>
            <uri>https://mingle.example.com/api/v2/users/233.xml</uri>
          </author>
        </entry>
      }
      entry = Feed::Entry.from_snippet(element_xml_text)
    end
    
    
  end
end
