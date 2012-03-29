module MingleEvents
  class ZipDirectory
    
    def initialize(name)
      FileUtils.mkdir_p(File.dirname(name))
      @root = name
      @entry_map = nil
      @readio = nil
    end

    def write_file(path, &block)
      measure('write_file') do
        exists = File.exists?(@root) && File.lstat(@root).size > 1024
        writeio = File.open(@root, exists ? 'r+b' : 'wb')
        # for a existing tar, seek to -1024 from end to skip 1024 '\0' in tar format
        writeio.seek(-1024, IO::SEEK_END) if exists

        Archive::Tar::Minitar::Output.open(writeio) do |output|
          stat = {:mode => 0100644, :mtime => Time.now}
          output.tar.add_file(path, stat) { |io, opts| yield(io) }
        end
      end
    end

    def file(path, &block)
      measure("read file") do
        raise "File at '#{path}' in archive '#{@root}' dose not exisits" unless exists?(path)
        entry_map[path].open { |entry_stream| yield(entry_stream) }
      end
    end

    def exists?(path)
      return unless File.exists?(@root)
      entry_map.include?(path)
    end

    def delete
      close
      FileUtils.rm_rf(@root)
    end

    def close
      @readio.close if @readio
      @readio = nil
      @entry_map = nil
    end

    alias :reload :close

    private

    class ReusableEntryStream < Archive::Tar::Minitar::Reader::EntryStream
      def open(&block)
        rewind
        yield(self)
      end

      def close
        # do nothing
      end
    end

    def entry_map
      return @entry_map if @entry_map
      
      @entry_map = {}
      measure("entries archive loading") do
        @readio = File.open(@root, 'rb')
        loop do
          break if @readio.eof?
        
          header = Archive::Tar::PosixHeader.new_from_stream(@readio)
          break if header.empty?
          
          entry = ReusableEntryStream.new(header, @readio)
          size  = entry.size
          @entry_map[entry.name] = entry

          skip = (512 - (size % 512)) % 512
          @readio.seek(size - entry.bytes_read, IO::SEEK_CUR)
          @readio.read(skip) # discard trailing zeros
        end
        @readio.rewind
      end
      @entry_map
    end

    def measure(label=nil, &block)
      return yield unless ENV['MINGLE_EVENTS_VERBOSE']
      start = Time.now
      yield.tap { puts "ZipDirectory##{label}: using #{Time.now - start}s"}
    end
  end
end
