require 'thor'
$:.unshift File.join(File.dirname(__FILE__), '..')
require 's3archive/compress_and_upload'

module S3Archive
  class Cli < Thor
    namespace :s3archive

    class_option "-c",
      :desc => "Path to config file",
      :banner => "CONFIG_FILE",
      :type => :string,
      :aliases => "--config",
      :default => "/etc/s3archive.yml"

    desc "upload PATH [PATH...]", "Compresses PATH and uploads to s3://<bucket>/<year>/<month>/<day>/<filename>.gz"
    def upload (*paths)
      S3Archive.config_path = self.options["c"] if self.options["c"]
      help(:upload) && exit if paths.empty?
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
