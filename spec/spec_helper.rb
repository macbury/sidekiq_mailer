$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'action_mailer'
require 'sidekiq_mailer'
require 'rspec/autorun'


Sidekiq::Mailer.excluded_environments = []
ActionMailer::Base.delivery_method = :test
ActionMailer::Base.prepend_view_path File.join(File.dirname(__FILE__), 'support')
