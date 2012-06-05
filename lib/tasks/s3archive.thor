require 'thor'
$:.unshift File.join(File.dirname(__FILE__), '..')
require 's3archive/postrotate'
require 's3archive/compress_and_upload'
require 's3archive/db_dump'
require 's3archive/logging'

module S3Archive
  class Cli < Thor
    include ::S3Archive::Logging
    namespace :s3archive

    class_option :config,
      :desc => "Path to config file",
      :banner => "CONFIG_FILE",
      :type => :string,
      :aliases => "-c",
      :default => "/etc/s3archive.yml"

    desc "postrotate LOGFILE [LOGFILE...]", "A postrotate hook for logrotate."
    long_desc <<-EOF
Uploads the logfile that was rotated yesterday! I.e., after
logrotate has run, you will typically three files: application.log-20100805.gz
(this is the file that is uploaded), application.log-20100806 and
application.log.

Note: For this to work, you *must* have the following stanzas in
the logrotate configuration: compress, delayedcompress, dateext & ifempty.
EOF

    def postrotate (*paths)
      set_config
      help(:postrotate) && exit if paths.empty?

      paths.each do |path|
        begin
          ::S3Archive::Postrotate.run(path)
        rescue Exception => e
          logger.error(e)
        end
      end
    end

    desc "upload FILE [FILE...]", "Uploads the file(s) (compressed) to s3://bucket/<hostname>/<year>/<month>/<day>/<filename>.gz"
    def upload (*paths)
      set_config
      help(:upload) && exit if paths.empty?

      paths.each do |path|
        begin
          ::S3Archive::CompressAndUpload.run(path)
        rescue Exception => e
          logger.error(e)
        end
      end
    end

    desc "genconfig", "Prints a sample config file to stdout"
    def genconfig
      puts ::S3Archive::Config.sample_yaml
    end

    desc "dbdump [options] CONFIG_PATH", "Dump database for ENV (default production) and upload"
    method_option :environment,
    :aliases => '-e',
    :type => :string,
    :default => 'production',
    :banner => 'ENV',
    :desc => "Use db configuration from this environment."
    long_desc <<-EOT
Dump and archive a database specified in the rails-style YAML file at CONFIG_PATH.
By default the production database will be dumped.
EOT
    def dbdump(yaml_path)
      db_config = YAML.load_file(yaml_path)[options[:environment]]
      dumper = ::S3Archive::DbDump.new(db_config)
      begin
        dumper.run
        set_config
        ::S3Archive::CompressAndUpload.run(dumper.dump_path)
      rescue Exception => e
        logger.error(e)
      end
    end

    no_tasks do
      def set_config
        unless File.exists?(options[:config])
          logger.error("Could not find config file #{options[:config]}")
          exit(1)
        end
        ::S3Archive.config_path = options[:config]
      end
    end
  end
end
