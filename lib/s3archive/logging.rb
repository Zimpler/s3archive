require 'logger'

module S3Archive
  module Logging
    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end
