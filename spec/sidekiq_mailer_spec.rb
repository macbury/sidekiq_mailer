require 'spec_helper'

class Rails3Mailer < ActionMailer::Base
  include Sidekiq::Mailer
  default :from => "from@example.org", :subject => "Subject"
  MAIL_PARAMS = { :to => "crafty@example.org" }

  def test_mail(*params)
    Sidekiq::Mailer.success!
    mail(*params)
  end
end
class DelayProxy;def send(method_name, args);end;end

describe Sidekiq::Mailer do
  let(:logger) { double(:logger, :error => nil) }
  let(:delay_object) { DelayProxy.new }

  before do
    ActionMailer::Base.stub(:delay).and_return(delay_object)
    Sidekiq::Mailer.stub(:success!)
    Rails3Mailer.logger = logger
  end

  describe '#deliver' do
    before(:all) do
      @delivery = lambda {
        Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver
      }
    end

    it 'should not deliver the email synchronously' do
      lambda { @delivery.call }.should_not change(ActionMailer::Base.deliveries, :size)
    end

    it "should use the ActionMailer delayed extension with the default queue" do
      expect(delay_object).to receive(:send).with(:test_mail, [{:to=>"crafty@example.org"}])
      @delivery.call
    end

    context "when current env is excluded" do
      it 'should not deliver through Sidekiq for excluded environments' do
        Sidekiq::Mailer.stub(:excluded_environments => [:custom])
        Sidekiq::Mailer::MessageDecoy.any_instance.should_receive(:current_env).twice.and_return(:custom)
        expect(delay_object).to_not receive(:send)
        @delivery.call
      end
    end

    it 'should not invoke the method body more than once' do
      Sidekiq::Mailer.should_not_receive(:success!)
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver
    end

    context "when redis is not available" do
      module Redis
        class CannotConnectError < RuntimeError; end
      end

      before do
        ActionMailer::Base.stub(:delay).and_raise(Redis::CannotConnectError)
      end

      it 'falls back to synchronous delivery automatically' do
        logger.should_receive(:error).at_least(:once)
        lambda { @delivery.call }.should change(ActionMailer::Base.deliveries, :size).by(1)
      end
    end
  end

  describe '#deliver!' do
    it 'should deliver the email synchronously' do
      lambda { Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).deliver! }.should change(ActionMailer::Base.deliveries, :size).by(1)
    end
  end

  describe 'original mail methods' do
    it 'should be preserved' do
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).subject.should == 'Subject'
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).from.should include('from@example.org')
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).to.should include('crafty@example.org')
    end

    it 'should require execution of the method body prior to queueing' do
      Sidekiq::Mailer.should_receive(:success!).once
      Rails3Mailer.test_mail(Rails3Mailer::MAIL_PARAMS).subject
    end
    context "when current env is excluded" do
      it 'should render email immediately' do
        Sidekiq::Mailer::MessageDecoy.any_instance.stub(:environment_excluded?).and_return(true)
        expect(delay_object).to_not receive(:send)
        params = {:subject => 'abc'}
        mail = Rails3Mailer.test_mail(params)
        params[:subject] = 'xyz'
        mail.to_s.should match('Subject: abc')
      end
    end
  end
end
