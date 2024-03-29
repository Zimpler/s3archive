require 'singleton'
require 'yaml'

module S3Archive
  def self.config_path=(config_path)
    @config_path = config_path
  end

  def self.config_path
    @config_path
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

    def self.sample_yaml
      {"bucket" => "BUCKET",
       "access_key_id" => "ACCESS_KEY_ID",
       "secret_access_key" => "SECRET_ACCESS_KEY_ID"}.to_yaml
    end
  end
end
