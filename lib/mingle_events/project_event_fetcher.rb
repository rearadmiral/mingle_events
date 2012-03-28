module MingleEvents
  
  # fetch all unseen events and write them to disk for future processing
  # 
  # this class is messy and needs some cleanup, but some things are in here
  # for a reason. specifically, for historical analysis, we can process each event,
  # one at at time, reading it off disk, to avoid massive memory consumption.
  class ProjectEventFetcher
    
    attr_reader :entry_cache
    
    def initialize(project_identifier, mingle_access, state_dir=nil)
      @project_identifier = project_identifier
      @mingle_access = mingle_access
      base_uri = URI.parse(mingle_access.base_url)
      @state_dir = state_dir || File.join('~', '.mingle_events', base_uri.host, base_uri.port.to_s)
      @state_dir = File.expand_path(File.join(@state_dir, project_identifier, 'fetched_events'))
      @entry_cache = EntryCache.new(@state_dir)
    end
    
    # blow away any existing state, when next used to fetch events from mingle
    # will crawl all the way back to time zero
    def reset
      @entry_cache.clear
    end
    
    def set_current_state_to_now_if_no_current_state
      return if @entry_cache.has_current_state?
      @entry_cache.set_current_state(page_with_latest_entries.entries.first)
    end
    
    # fetch the latest events from mingle, i.e., the ones not previously seen
    def fetch_latest
      page = page_with_latest_entries
      most_recent_new_entry = page.entries.first
      last_fetched_entry = @entry_cache.latest
      last_fetched_entry_seen = false      
      next_entry = nil
      while !last_fetched_entry_seen && page
        page.entries.each do |entry|
                    
          @entry_cache.write(entry, next_entry)
          if last_fetched_entry && entry.entry_id == last_fetched_entry.entry_id
            last_fetched_entry_seen = true
            break
          end

          next_entry = entry
        end
        page = page.next
      end
                  
      @entry_cache.update_current_state(next_entry, most_recent_new_entry)
      @entry_cache.entries(next_entry, most_recent_new_entry)
    end
    
    # returns all previously fetched entries; can be used to reprocess the events for, say,
    # various historical analyses
    def all_fetched_entries
      @entry_cache.all_entries
    end
    
    def first_entry_fetched      
      @entry_cache.first
    end
    
    def last_entry_fetched
      @entry_cache.latest
    end
                   
    private
    
    def page_with_latest_entries
      Feed::Page.new("/api/v2/projects/#{@project_identifier}/feeds/events.xml", @mingle_access)
    end        
  end
end
