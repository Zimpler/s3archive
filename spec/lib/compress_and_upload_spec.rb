require 'spec_helper'
require 's3archive/compress_and_upload'
require 'tempfile'

module S3Archive
  describe CompressAndUpload do
    before do
      S3FileSynchronizer.stub!(:new).and_return(
        mock("S3FileSynchronizer", :run => true)
      )
      Tempfile.open('test_file') do |test_file|
        @cau = S3Archive::CompressAndUpload.new(test_file.path)
        @cau.logger.level = Logger::UNKNOWN
      end
    end

    describe "#run" do
      it "logs and returns when the file doesn't exist" do
        @cau.stub!(:path).and_return("this path does not exist")
        @cau.logger.should_receive(:error)
        S3Archive::S3FileSynchronizer.should_not_receive(:run)
        @cau.run
      end

      it "compresses the file if deemed necessary" do
        @cau.stub!(:compress?).and_return(true)
        @cau.should_receive(:compress!)
        @cau.run
      end
    end

    describe "#compress?" do
      it "returns false if the filename ends with .gz" do
        @cau.stub!(:path).and_return("filename.gz")
        @cau.send(:compress?).should be_false
      end
      it "return true otherwise" do
        @cau.stub!(:path).and_return("filename")
        @cau.send(:compress?).should be_true
      end
      it "caches the answer" do
        @cau.stub!(:path).and_return("filename.gz")
        @cau.logger.should_receive(:info).once
        @cau.send(:compress?).should be_false
        @cau.send(:compress?).should be_false
      end
    end

    it "should have way more tests"
  end
end
