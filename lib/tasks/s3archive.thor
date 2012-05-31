require 'thor'
$:.unshift File.join(File.dirname(__FILE__), '..')
require 's3archive/compress_and_upload'
require 's3archive/logging'

module S3Archive
  class Cli < Thor
    include Logging
    namespace :s3archive

    class_option :config,
      :desc => "Path to config file",
      :banner => "CONFIG_FILE",
      :type => :string,
      :aliases => "-c",
      :default => "/etc/s3archive.yml"

    desc "upload PATH [PATH...]", "Sleeps, compresses and uploads to s3://<bucket>/<year>/<month>/<day>/<filename>.gz"
    method_option :sleep,
                  :aliases => "-s",
                  :default => 5,
                  :banner => "SECONDS",
                  :desc => "The number of seconds to sleep before uploading"

    def upload (*paths)
      unless File.exists?(options[:config])
        logger.error("Could not find config file #{options[:config]}")
        exit(1)
      end

      S3Archive.config_path = options[:config]
      help(:upload) && exit if paths.empty?

      logger.info("Sleeping for #{options[:sleep]} seconds") && sleep(options[:sleep])
      paths.each do |path|
        CompressAndUpload.run(path)
      end
    end

    desc "genconfig", "Prints a sample config file to stdout"
    def genconfig
      puts S3Archive::Config.sample_yaml
    end
  end
end
