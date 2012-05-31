# The main entry point db:backup_to_s3 is run by /etc/logrotate.d/rails3app
# daily. changed

require 'thor'
require 'socket'  # For hostname
require 'tempfile'
require_relative 'logging'
require_relative 'config'
require_relative 's3_file_synchronizer'

module S3Archive
  class Postrotate
    include Logging

    def self.run(logfile_path)
      new(logfile_path).run
    end

    attr_reader :logfile_path
    def initialize(logfile_path)
      @logfile_path = logfile_path
    end

    def run
      raise "Could not find #{prev_logfile}" unless File.exists?(prev_logfile)
      bucket = S3Archive.config.bucket
      logger.info("* Uploading #{prev_logfile} to s3://#{bucket}/#{key}")
      S3FileSynchronizer.run(prev_logfile, bucket, key)
    end

    private

    def key
      year, month, day = prev_date.strftime("%Y-%m-%d").split('-') # Quick & dirty way to obtain leading zeroes in months and days
      [hostname, year, month, day, File.basename(prev_logfile)].join('/')
    end

    def hostname
      Socket.gethostname
    end

    def prev_logfile
      "#{logfile_basename}-#{prev_date_str}.gz"
    end

    def prev_date_str
      prev_date.strftime("%Y%m%d")
    end

    def prev_date
      logfile_date.prev_day
    end

    def logfile_date
      parse_logfile_path unless @logfile_date
      @logfile_date
    end

    def logfile_basename
      parse_logfile_path unless @logfile_basename
      @logfile_basename
    end

    def parse_logfile_path
      logfile_path =~ /\A(.*)-(\d{8})\z/ || raise("Could not parse logfile path")
      @logfile_basename = $1
      @logfile_date = Date.strptime($2, "%Y%m%d")
    end
  end
end
