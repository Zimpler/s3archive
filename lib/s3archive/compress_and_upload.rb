# The main entry point db:backup_to_s3 is run by /etc/logrotate.d/rails3app
# daily. changed

require 'thor'
require 'socket'  # For hostname
require 'tempfile'
require_relative 'logging'
require_relative 'config'
require_relative 's3_file_synchronizer'

module S3Archive
  class CompressAndUpload
    include Logging

    def self.run(path)
      new(path).run
    end

    attr_reader :path
    def initialize(path)
      @path = path
    end

    def run
      unless File.exists?(path)
        logger.error("COULD NOT FIND '#{path}'")
        return
      end

      logger.info("* Processing #{path}")

      compress! if compress?
      upload!
      delete_tempfile! if compress?
    end

    private
    def compress?
      unless defined? @compression_needed
        if path.end_with?('.gz') || path.end_with?('.tgz')
          logger.info("** #{path} already compressed, skipping compression")
          @compression_needed = false
        else
          @compression_needed = true
        end
      end
      @compression_needed
    end

    def compress!
      logger.info("** Compressing #{path} to #{tempfile.path}")
      system "gzip -n -c < #{path} > #{tempfile.path}"
    end

    def upload!
      bucket = S3Archive.config.bucket
      logger.info("** Uploading #{path_to_upload} to s3://#{bucket}/#{key}")
      S3FileSynchronizer.run(path_to_upload, bucket, key)
    end

    def path_to_upload
      compress? ? tempfile.path : path
    end

    def delete_tempfile!
      logger.info("** Deleting #{tempfile.path}")
      tempfile.unlink
    end

    def tempfile
      @tempfile ||= begin
        tempfile = Tempfile.new([filename, '.gz'])
        tempfile.close # An external process will write to it
        tempfile
      end
    end

    def key
      year, month, day = Time.now.strftime("%Y-%m-%d").split('-')
      [hostname, year, month, day, basename_gz].join('/')
    end

    def basename_gz
      compress? ? "#{filename}.gz" : filename
    end

    def filename
      @filename ||= File.basename(path)
    end

    def hostname
      Socket.gethostname
    end
  end
end


if $0 == __FILE__
  path = File.join(File.dirname(__FILE__), 'config.rb')
  S3Archive::CompressAndUpload.run(path)

#  bucket = 'this.is.my.test.bucket'
#  key = 'this is a folder/foobar'
#  S3FileSynchronizer.run(in_path, bucket, key)
end
