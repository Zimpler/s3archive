require 'spec_helper'
require 's3archive/db_dump'

module S3Archive
  describe DbDump do
    let(:dump) do
      d = DbDump.new(@config)
      d.logger.level = Logger::UNKNOWN
      d
    end
    context "with a mysql config" do
      it "runs mysqldump" do
        @config = {'adapter' => 'mysql', 'database' => 'the_db', 'username' => 'the_user', 'host' => 'here'}
        dump.should_receive(:system).with(/^mysqldump -u the_user .* -h here the_db/)
        dump.run

        dump.dump_path.should match '/tmp/dbdump'
      end
    end

    it "should have way more tests"
  end
end
