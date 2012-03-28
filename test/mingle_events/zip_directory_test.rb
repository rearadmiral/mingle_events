require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))

module MingleEvents
  class ZipDirectoryTest < Test::Unit::TestCase

    def setup
      @dir = ZipDirectory.new("/tmp/foo")
      @dir.delete
    end

    def teardown
      @dir.close
    end

    def test_read_write_files
      @dir.write_file('a') { |f| f.write('s' * 1000) }
      @dir.reload
      assert_equal 's' * 1000, @dir.file('a', &:read)
    end

    def test_read_write_files_with_sub_directory
      @dir.write_file('a/b/c') { |f| f.write( 's' * 1000) }
      @dir.reload
      assert_equal 's' * 1000, @dir.file('a/b/c', &:read)
    end

    def test_appending_files
      @dir.write_file('a/b/c') { |f| f.write( 's' * 1000) }
      @dir.write_file("e/f/g") { |f| f.write( "t" * 1000) }
      @dir.reload
      assert_equal 's' * 1000, @dir.file('a/b/c', &:read)
      assert_equal 't' * 1000, @dir.file('e/f/g', &:read)
    end

    def test_update_file
      @dir.write_file('a') { |f| f.write( 's' * 1000) }
      @dir.write_file('a') { |f| f.write( 't' * 1000) }
      @dir.reload

      assert_equal 't' * 1000, @dir.file('a', &:read)
    end

  end
end
