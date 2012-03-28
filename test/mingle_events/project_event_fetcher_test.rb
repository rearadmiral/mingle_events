require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))

module MingleEvents
  class ProjectEventFetcherTest < Test::Unit::TestCase
    
    def test_can_fetch_all_entries_and_write_to_disk_when_no_initial_state
      state_dir = temp_dir
      fetcher = ProjectEventFetcher.new('atlas', stub_mingle_access, state_dir)  
      
      latest_entries = fetcher.fetch_latest
      expected_latest_entries = [23, 97, 98, 99, 100, 101, 103].map{|n| entry(n)}
      assert_equal(expected_latest_entries, latest_entries.to_a)
      assert_equal entry(23), fetcher.first_entry_fetched
      assert_equal entry(103), fetcher.last_entry_fetched
    end
    
    def test_can_fetch_all_entries_and_write_to_disk_when_existing_state
      state_dir = temp_dir
      fetcher = ProjectEventFetcher.new('atlas', stub_mingle_access, state_dir)
      
      setup_current_state(23, 97, 97, fetcher)
      
      latest_entries = fetcher.fetch_latest
      expected_latest_entries = [98, 99, 100, 101, 103].map{|n| entry(n)}

      assert_equal(expected_latest_entries.collect(&:entry_id), latest_entries.to_a.collect(&:entry_id))
      assert_equal entry(23), fetcher.first_entry_fetched
      assert_equal entry(103), fetcher.last_entry_fetched
    end
    
    def test_should_connect_existing_entries_and_newly_fetched_entries
      state_dir = temp_dir
      access = stub_mingle_access
      fetcher = ProjectEventFetcher.new('atlas', access, state_dir)

      fetcher.fetch_latest

      feed_xml_with_new_entries = <<-XML
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:mingle="http://www.thoughtworks-studios.com/ns/mingle">

          <link href="https://mingle.example.com/api/v2/projects/atlas/feeds/events.xml" rel="current"/>
          <link href="https://mingle.example.com/api/v2/projects/atlas/feeds/events.xml" rel="self"/>
          <link href="https://mingle.example.com/api/v2/projects/atlas/feeds/events.xml?page=2" rel="next"/>

          <entry>
            <id>https://mingle.example.com/projects/atlas/events/index/105</id>
            <title>entry 105</title>
            <updated>2011-02-03T08:12:42Z</updated>
            <author><name>Bob</name></author>
          </entry>
          <entry>
            <id>https://mingle.example.com/projects/atlas/events/index/104</id>
            <title>entry 104</title>
            <updated>2011-02-03T08:12:42Z</updated>
            <author><name>Bob</name></author>
          </entry>

          <entry>
            <id>https://mingle.example.com/projects/atlas/events/index/103</id>
            <title>entry 103</title>
            <updated>2011-02-03T08:12:42Z</updated>
            <author><name>Bob</name></author>
          </entry>
          <entry>
            <id>https://mingle.example.com/projects/atlas/events/index/101</id>
            <title>entry 101</title>
            <updated>2011-02-03T02:09:16Z</updated>
            <author><name>Bob</name></author>
          </entry>
          <entry>
            <id>https://mingle.example.com/projects/atlas/events/index/100</id>
            <title>entry 100</title>
            <updated>2011-02-03T01:58:02Z</updated>
            <author><name>Mary</name></author>
          </entry>
        </feed>
      XML

      access.register_page_content('https://mingle.example.com/api/v2/projects/atlas/feeds/events.xml', feed_xml_with_new_entries)
      access.register_page_content('/api/v2/projects/atlas/feeds/events.xml', feed_xml_with_new_entries)

      fetcher.fetch_latest

      assert_equal ['https://mingle.example.com/projects/atlas/events/index/104', 'https://mingle.example.com/projects/atlas/events/index/105'], fetcher.all_fetched_entries.map(&:entry_id)[-2..-1]
    end

    def test_no_new_entries_with_current_state
      state_dir = temp_dir
      fetcher = ProjectEventFetcher.new('atlas', stub_mingle_access, state_dir)
      setup_current_state(23, 97, 103, fetcher)

      assert fetcher.fetch_latest.to_a.empty?
      assert_equal entry(23), fetcher.first_entry_fetched
      assert_equal entry(103), fetcher.last_entry_fetched
    end
    
    def test_no_new_entries_with_no_current_state
      state_dir = temp_dir
      mingle_access = StubMingleAccess.new
      mingle_access.register_page_content('/api/v2/projects/atlas/feeds/events.xml', EMPTY_EVENTS_XML)
      fetcher = ProjectEventFetcher.new('atlas', mingle_access, state_dir)
      
      assert fetcher.fetch_latest.to_a.empty?
      assert_nil fetcher.first_entry_fetched
      assert_nil fetcher.last_entry_fetched
    end
    
    def test_set_current_state_to_now_if_no_current_state_when_project_has_previous_history
      state_dir = temp_dir
      mingle_access = stub_mingle_access
      fetcher = ProjectEventFetcher.new('atlas', mingle_access, state_dir)

      fetcher.set_current_state_to_now_if_no_current_state
      assert fetcher.fetch_latest.to_a.empty?
      
      mingle_access.register_page_content('/api/v2/projects/atlas/feeds/events.xml',%{
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:mingle="http://www.thoughtworks-studios.com/ns/mingle">

          <link href="https://mingle.example.com/api/v2/projects/atlas/feeds/events.xml" rel="current"/>
          <link href="https://mingle.example.com/api/v2/projects/atlas/feeds/events.xml" rel="self"/>
          <link href="https://mingle.example.com/api/v2/projects/atlas/feeds/events.xml?page=2" rel="next"/>

          <entry>
            <id>https://mingle.example.com/projects/atlas/events/index/104</id>
            <title>entry 104</title>
            <updated>2011-02-03T08:14:42Z</updated>
            <author><name>Bob</name></author>
          </entry>
          <entry>
            <id>https://mingle.example.com/projects/atlas/events/index/103</id>
            <title>entry 103</title>
            <updated>2011-02-03T08:12:42Z</updated>
            <author><name>Bob</name></author>
          </entry>
        </feed>
      })
            
      assert_equal([entry(104)], fetcher.fetch_latest.to_a)
    end
    
    def test_set_current_state_to_now_if_no_current_state_is_ignored_if_there_is_already_local_current_state
      state_dir = temp_dir
      mingle_access = stub_mingle_access
      fetcher = ProjectEventFetcher.new('atlas', mingle_access, state_dir)
      fetcher.fetch_latest  # bring current state up to 103
            
      mingle_access.register_page_content('/api/v2/projects/atlas/feeds/events.xml',%{
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:mingle="http://www.thoughtworks-studios.com/ns/mingle">

          <link href="https://mingle.example.com/api/v2/projects/atlas/feeds/events.xml" rel="current"/>
          <link href="https://mingle.example.com/api/v2/projects/atlas/feeds/events.xml" rel="self"/>
          <link href="https://mingle.example.com/api/v2/projects/atlas/feeds/events.xml?page=2" rel="next"/>

          <entry>
            <id>https://mingle.example.com/projects/atlas/events/index/104</id>
            <title>entry 104</title>
            <updated>2011-02-03T08:14:42Z</updated>
            <author><name>Bob</name></author>
          </entry>
          <entry>
            <id>https://mingle.example.com/projects/atlas/events/index/103</id>
            <title>entry 103</title>
            <updated>2011-02-03T08:12:42Z</updated>
            <author><name>Bob</name></author>
          </entry>
        </feed>
      })
            
      fetcher.set_current_state_to_now_if_no_current_state
      assert_equal([entry(104)], fetcher.fetch_latest.to_a)
    end
    
    def test_subseuqnce_set_current_state_to_now_if_no_current_state_calls_when_project_initially_had_no_history_do_not_prevent_initial_events_from_being_seen
      state_dir = temp_dir
      mingle_access = StubMingleAccess.new
      mingle_access.register_page_content('/api/v2/projects/atlas/feeds/events.xml', EMPTY_EVENTS_XML)
      fetcher = ProjectEventFetcher.new('atlas', mingle_access, state_dir)
      fetcher.set_current_state_to_now_if_no_current_state
      assert fetcher.fetch_latest.to_a.empty?
      
      mingle_access.register_page_content('/api/v2/projects/atlas/feeds/events.xml',%{
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:mingle="http://www.thoughtworks-studios.com/ns/mingle">

          <link href="https://mingle.example.com/api/v2/projects/atlas/feeds/events.xml" rel="current"/>
          <link href="https://mingle.example.com/api/v2/projects/atlas/feeds/events.xml" rel="self"/>

          <entry>
            <id>https://mingle.example.com/projects/atlas/events/index/104</id>
            <title>entry 104</title>
            <updated>2011-02-03T08:14:42Z</updated>
            <author><name>Bob</name></author>
          </entry>
        </feed>
      })
      fetcher.set_current_state_to_now_if_no_current_state
      assert_equal([entry(104)], fetcher.fetch_latest.to_a)
    end
    
    private
    
    def setup_current_state(first_entry_id, second_entry_id, last_entry_id, fetcher)    
      first_entry = entry(first_entry_id)
      second_entry = entry(second_entry_id)
      last_entry = entry(last_entry_id)
      fetcher.entry_cache.write(first_entry, second_entry)
      fetcher.entry_cache.write(last_entry, nil)  
      fetcher.entry_cache.update_current_state(first_entry, last_entry)
    end
            
    def entry(entry_id)
      entry_xml = %{
        <entry xmlns="http://www.w3.org/2005/Atom">
          <id>https://mingle.example.com/projects/atlas/events/index/#{entry_id}</id>
          <title>entry #{entry_id}</title>
          <updated>2011-02-03T01:10:52Z</updated>
          <author><name>Bob</name></author>
        </entry>
      }
      Feed::Entry.from_snippet(entry_xml)
    end
  end
end
