require 'thor'
$:.unshift File.join(File.dirname(__FILE__), '..')
require 's3archive/compress_and_upload'
require 's3archive/logging'

module S3Archive
  class DbDump
    include Logging

    attr_reader :db_config, :dump_path, :name

    def initialize(db_config, name = 'dbdump')
      @db_config = db_config
      @name = name.gsub(/\s+/, '_')
    end

    def run
      backup_filename = "#{name}-#{Time.now.utc.strftime("%Y%m%dT%H%M%S")}.sql.gz"
      backup_path = "/tmp/#{backup_filename}"
      logger.info "* Dumping and compressing data to #{backup_path}."
      case db_config['adapter']
      when /^mysql/
        db_host = db_config['host']
        db_name = db_config['database']
        password = "-p#{db_config['password']}" if db_config['password']
        backup_options = "--opt --skip-lock-tables --single-transaction --skip-extended-insert"
        dump_options = "-u #{db_config['username']} #{password} #{backup_options} -h #{db_host} #{db_name}"
        logger.info "** Backing up mysql db #{db_name}@#{db_host}"
        system "mysqldump #{dump_options} | gzip -c > #{backup_path}"
      else
        db_config.delete 'password'
        msg = "Don't know how to dump #{db_config['adapter']} database: #{db_config.inspect}'"
        logger.fatal msg
        raise msg
      end

      @dump_path = backup_path
    end
  end
end
