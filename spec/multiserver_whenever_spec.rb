require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

describe MultiserverWhenever do
  subject { MultiserverWhenever.new }
  
  let :cron_contents do
    <<-CRON
# Begin Whenever generated tasks for: /path/to/project/config/whenever/search.rb
0 17 * * * /bin/bash -l -c 'echo '\''search'\'''

# End Whenever generated tasks for: /path/to/project/config/whenever/search.rb

# Non-whenever crontab here

# Begin Whenever generated tasks for: /path/to/project/config/whenever/emails.rb
0 7 * * * /bin/bash -l -c 'echo '\''emails'\'''

# End Whenever generated tasks for: /path/to/project/config/whenever/emails.rb
CRON
  end
  
  let(:hostname) { `hostname`.strip }
  let :config_contents_single do
    <<-CONFIG
---
decoy1.local: search
decoy2.local:
  - search
  - emails
#{hostname}: emails
CONFIG
  end
  
  let :config_contents_double do
    <<-CONFIG
---
decoy1.local: search
decoy2.local:
  - search
  - emails
#{hostname}: 
  - emails
  - search
CONFIG
  end
  
  let :config_contents_blank do
    <<-CONFIG
---
decoy1.local: search
decoy2.local:
  - search
  - emails
CONFIG
  end
  
  let(:root_dir) { File.expand_path File.dirname(File.dirname(__FILE__)) }
  
  describe "clear!" do
    before(:each) do
      subject.stub!(:read_cron).and_return(cron_contents)
    end
    
    it "should run whenever commands to clear the cron entries" do
      subject.should_receive(:whenever).with("--load-file config/whenever/do_not_remove.rb --clear-crontab /path/to/project/config/whenever/search.rb --set environment=production")
      subject.should_receive(:whenever).with("--load-file config/whenever/do_not_remove.rb --clear-crontab /path/to/project/config/whenever/emails.rb --set environment=production")
      subject.clear!
    end
  end
  
  describe "write!" do
    context "with default (production) environment" do
      context "with no config for this host" do
        before(:each) do
          subject.stub!(:read_config).and_return(config_contents_blank)
        end

        it "should not run any whenever commands" do
          subject.should_not_receive(:whenever)
          subject.write!
        end
      end

      context "with one role for this host" do
        before(:each) do
          subject.stub!(:read_config).and_return(config_contents_single)
        end

        it "should the whenever update command for the one role" do
          subject.should_receive(:whenever).with("--load-file config/whenever/emails.rb --update-crontab #{root_dir}/config/whenever/emails.rb --set environment=production")
          subject.write!
        end
      end

      context "with multiple role for this host" do
        before(:each) do
          subject.stub!(:read_config).and_return(config_contents_double)
        end

        it "should not run the whenever update command for each role" do
          subject.should_receive(:whenever).with("--load-file config/whenever/emails.rb --update-crontab #{root_dir}/config/whenever/emails.rb --set environment=production")
          subject.should_receive(:whenever).with("--load-file config/whenever/search.rb --update-crontab #{root_dir}/config/whenever/search.rb --set environment=production")
          subject.write!
        end
      end
    end
    
    context "with specified qa environment" do
      subject { MultiserverWhenever.new(:environment => 'qa') }
      
      before(:each) do
        subject.stub!(:read_config).and_return(config_contents_single)
      end

      it "should set the environment with the --set args" do
        subject.should_receive(:whenever).with("--load-file config/whenever/emails.rb --update-crontab #{root_dir}/config/whenever/emails.rb --set environment=qa")
        subject.write!
      end
    end
    
  end
end