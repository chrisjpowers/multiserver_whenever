require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

describe MultiserverWheneverizer do
  subject { MultiserverWheneverizer.new }
  
  let(:root_path) { File.dirname(File.dirname __FILE__) }
  
  describe "run!" do
    before(:each) do
      subject.stub!(:write_config!)
      subject.stub!(:copy_whenever_files!)
    end
    
    it "should copy the config" do
      subject.should_receive(:write_config!)
      subject.run!
    end
    
    it "should copy the whenever files" do
      subject.should_receive(:copy_whenever_files!)
      subject.run!
    end
  end
  
  describe "write_config!" do
    before(:each) do
      FileUtils.stub!(:mkdir_p)
      File.stub!(:open)
    end
    
    after(:each) do
      subject.write_config!
    end
    
    it "should create ensure the config dir is there" do
      FileUtils.should_receive(:mkdir_p).with("config")
    end
    
    it "should write to config/whenever.yml" do
      File.should_receive(:open).with('config/whenever.yml', 'w')
    end
  end
  
  describe "custom_config" do
    it "should render a config with the hostname with example" do
      hostname = `hostname`.strip
      expected = <<-CONFIG
---
#{hostname}:
  - example
CONFIG
      subject.custom_config.should == expected.strip
    end
  end
  
  describe "copy_whenever_files!" do
    before(:each) do
      FileUtils.stub!(:mkdir_p)
      FileUtils.stub!(:cp)
      FileUtils.stub!(:cp_r)
    end
    
    after(:each) do
      subject.copy_whenever_files!
    end
    
    it "should create ensure the config/whenever dir is there" do
      FileUtils.should_receive(:mkdir_p).with("config/whenever")
    end
    
    it "should copy the whenever template files into config/whenever" do
      FileUtils.should_receive(:cp_r).with("#{root_path}/templates/config/whenever/.", "config/whenever")
    end
  end
end