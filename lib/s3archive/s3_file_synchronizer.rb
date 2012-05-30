require 'right_aws'
require 'digest/md5'
require_relative 'logging'

module S3Archive
  class S3FileSynchronizer
    include Logging

    attr_reader :local_file, :s3_file
    def initialize(local_file, s3_file)
      @local_file = local_file
      @s3_file    = s3_file
    end

    def run
      if s3_file.exists?
        if s3_file.md5_hex == local_file.md5_hex
          logger.info("'#{s3_file}' already exists and has correct checksum")
          nil
        else
          new_s3_file = S3File.new(s3_file.bucket, "#{s3_file.key}.#{local_file.md5_hex}")
          logger.error("'#{s3_file}' already exists and has wrong checksum. Uploading to '#{new_s3_file}'.")
          new_s3_file.put(local_file)
        end
      else
        s3_file.put(local_file)
      end
    end

    def self.run(local_path, bucket, key)
      local_file = LocalFile.new(local_path)
      s3_file = S3File.new(bucket, key)

      new(local_file, s3_file).run
    end
  end

  # Just a wrapper around a path with some md5 functions
  LocalFile = Struct.new(:path) do
    include Logging

    def open(*args, &block)
      File.open(path, *args, &block)
    end

    def md5_hex
      md5.hexdigest
    end

    def md5_base64
      md5.base64digest
    end

    def md5
      @md5 ||= Digest::MD5.file(path)
    end

    def to_s
      path
    end
  end

  # A wrapper around a s3 path (bucket, key) with some md5 and a put function
  S3File = Struct.new(:bucket, :key) do
    include Logging

    def md5_hex
      exists? && headers.fetch("etag").tr('"', '')
    end

    def exists?
      !headers.nil?
    end

    def put(local_file)
      local_file.open do |file|
        logger.info("Putting '#{local_file}' to '#{self}'")
        s3interface.put(bucket, key, file, 'Content-MD5' => local_file.md5_base64)
      end
    end

    def to_s
      "s3://#{bucket}/#{key}"
    end

    private
    def headers
      @headers ||= without_close_on_error do
        begin
          s3interface.head(bucket, key)
        rescue RightAws::AwsError => e
          raise unless e.http_code.to_s == '404'
        end
      end
    end

    def without_close_on_error(&block)
      old_val = RightAws::AWSErrorHandler.close_on_error
      RightAws::AWSErrorHandler.close_on_error = false
      block.call
    ensure
      RightAws::AWSErrorHandler.close_on_error = old_val
    end

    def s3interface
      @s3interface ||= RightAws::S3Interface.new(
        S3Archive.config.access_key_id,
        S3Archive.config.secret_access_key,
        :logger => logger
      )
    end
  end
end
