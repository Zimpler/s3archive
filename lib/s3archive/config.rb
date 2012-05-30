require 'singleton'
require 'yaml'

module S3Archive
  def self.config_path=(config_path)
    @config_path = config_path
  end

  def self.config_path
    @config_path || "/etc/s3archive.yml"
  end

  def self.config
    @config ||= Config.new(YAML.load(File.read(config_path)))
  end

  class Config
    attr_accessor :bucket, :access_key_id, :secret_access_key

    def initialize(params = {})
      params.each do |key, val|
        send("#{key}=", val)
      end
    end
  end
end
