require 'spec_helper'
require 's3archive/s3_file_synchronizer'

module S3Archive
  describe S3FileSynchronizer do
    before do
      @local_file = mock("LocalFile", :path => "local_dir/local_file.gz",)
      @s3_file    = mock("S3File", :bucket => "bucket", "key" => "a/key.gz")
      @syncer = S3FileSynchronizer.new(@local_file, @s3_file)
      @syncer.logger.level = Logger::UNKNOWN
    end

    context "when there is no matching S3 object" do
      before do
        @s3_file.stub!(:exists?).and_return(false)
      end

      it "uploads the file" do
        @s3_file.should_receive(:put).with(@local_file)
        @syncer.run
      end
    end

    context "when there is a matching S3 object" do
      before do
        @s3_file.stub!(:exists?).and_return(true)
      end

      context "with the correct checksum" do
        before do
          @local_file.stub!(:md5_hex).and_return('c0ffee')
          @s3_file.stub!(:md5_hex).and_return('c0ffee')
        end

        it "does nothing" do
          @s3_file.should_not_receive(:put)
          @syncer.run
        end
      end

      context "with the wrong checksum" do
        before do
          @local_file.stub!(:md5_hex).and_return('c0ffee')
          @s3_file.stub!(:md5_hex).and_return('7ee')
        end

        it "appends the checksum to the s3 file path and uploads" do
          new_bucket = @s3_file.bucket
          new_key = "#{@s3_file.key}.#{@local_file.md5_hex}"
          new_s3_file = mock("NewS3File", :bucket => new_bucket, :key => new_key)
          S3File.should_receive(:new).with(new_bucket, new_key).and_return(new_s3_file)

          new_s3_file.should_receive(:put).with(@local_file)
          @syncer.run
        end
      end
    end
  end
end
