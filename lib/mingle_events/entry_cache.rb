module MingleEvents
  class EntryCache
    def initialize(root_dir)
      @dir = ZipDirectory.new(root_dir)
    end
        
    def all_entries
      current_state = load_current_state
      Entries.new(@dir, current_state[:first_fetched_entry_info_file], current_state[:last_fetched_entry_info_file])
    end
    
    def entries(from_entry, to_entry)
      Entries.new(@dir, file_for_entry(from_entry), file_for_entry(to_entry))
    end
    
    def first
      current_state_entry(:first_fetched_entry_info_file)
    end
    
    def latest
      current_state_entry(:last_fetched_entry_info_file)
    end
    
    def write(entry, next_entry)
      file = file_for_entry(entry)
      file_content = {:entry_xml => entry.raw_xml, :next_entry_file_path => file_for_entry(next_entry)}
      @dir.write_file(file) {|out| YAML.dump(file_content, out)}
    end
    
    def has_current_state?
      @dir.exists?(current_state_file)
    end
    
    def set_current_state(latest_entry)
      return if latest_entry.nil?
      write(latest_entry, nil)
      update_current_state(latest_entry, latest_entry)
    end
    
    def update_current_state(oldest_new_entry, most_recent_new_entry)
      current_state = load_current_state
      current_state.merge!(:last_fetched_entry_info_file => file_for_entry(most_recent_new_entry))
      if current_state[:first_fetched_entry_info_file].nil?
        current_state.merge!(:first_fetched_entry_info_file => file_for_entry(oldest_new_entry))
      end
      @dir.write_file(current_state_file) { |out| YAML.dump(current_state, out)  }
    end

    def flush
      @dir.flush
    end
    
    def clear
      @dir.delete
    end
    
    private
    
    def load_current_state
      if has_current_state?
        @dir.file(current_state_file) { |f| YAML.load(f) }
      else
        {:last_fetched_entry_info_file => nil, :first_fetched_entry_info_file => nil}
      end
    end
    
    def current_state_file
      'current_state.yml'
    end
    
    def current_state_entry(info_file_key)
      if info_file = load_current_state[info_file_key]
        Feed::Entry.from_snippet((@dir.file(info_file) { |f| YAML.load(f) })[:entry_xml])
      end
    end
    
    def file_for_entry(entry)
      return nil if entry.nil?
      entry_id_as_uri = URI.parse(entry.entry_id)
      relative_path_parts = entry_id_as_uri.path.split('/').reject(&:blank?)
      entry_id_int = relative_path_parts.last
      insertions = ["#{entry_id_int.to_i/16384}", "#{entry_id_int.to_i%16384}"]
      relative_path_parts = relative_path_parts[0..-2] + insertions + ["#{entry_id_int}.yml"]  
      File.join(*relative_path_parts)
    end
    
    class ZipDirectory

      def initialize(name)
        FileUtils.mkdir_p(File.dirname(name))
        @root = name
        @unflushed = 0
        @zipfile = nil
      end

      def write_file(path, &block)
        zipfile.mkdir(File.dirname(path)) unless zipfile.find_entry(File.dirname(path)) 
        ret = zipfile.get_output_stream(path) { |f| yield(f) }
        @unflushed += 1
        if @unflushed >= 1000
          flush
          @unflushed = 0
        end
        ret
      end

      def file(path, &block)
        measure('read') { zipfile.get_input_stream(path) { |f| yield(f) } }
      end

      def exists?(path)
        return unless File.exists?(@root)
        zipfile.find_entry(path)
      end

      def delete
        FileUtils.rm_rf(@root)
      end

      def flush
        measure('flush') { @zipfile.commit if @zipfile }
      end

      private

      def measure(label=nil, &block)
        return yield unless ENV['MINGE_EVENTS_VERBOSE']
        start = Time.now
        yield.tap { puts "ZipDirectory##{label}: using #{Time.now - start}s"}
      end

      def zipfile
        @zipfile ||= measure('load') { Zip::ZipFile.open(@root, Zip::ZipFile::CREATE) }
      end

    end
    
    class Entries
      include Enumerable
      
      def initialize(state_dir, first_info_file, last_info_file)
        @dir = state_dir
        @first_info_file = first_info_file
        @last_info_file = last_info_file
      end
          
      def each(&block)
        current_file = @first_info_file
        while current_file
          current_entry_info = @dir.file(current_file) {|f| YAML.load(f) }
          yield(Feed::Entry.from_snippet(current_entry_info[:entry_xml]))
          break if current_file == @last_info_file
          current_file = current_entry_info[:next_entry_file_path]
        end
      end
    end
  end  
end
