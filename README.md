# SidekiqMailer

A gem plugin which allws messages prepared by ActionMailer to be delivered
asynchronously using Sidekiq.

Sidekiq provides an ActionMailer delayed extention which allows you to delay
mail in this format

  UserMailer.delay.send_welcome_email(new_user)

However if you  previously used ResqueMailer you previously have your delayed
mails configured like this

  UserMailer.send_welcome_email(new_user).deliver

This gem allows a sidekiq queuing system without having to change all mailer
calls within your project.

## Installation

Install the gem:

    gem install sidekiq_mailer

If you're using Bundler to manage your dependencies, you should add it to your
Gemfile:

    gem 'sidekiq_mailer'

## Usage

Include Sidekiq::Mailer in your ActionMailer subclass(es) like this:

    class MyMailer < ActionMailer::Base
      include Sidekiq::Mailer
    end

Now, when `MyMailer.subject_email(params).deliver` is called, an entry
will be created in the job queue.

Note that you can still have mail delivered synchronously by using the bang
method variant:

    MyMailer.subject_email(params).deliver!

## Testing

You don't want to be sending actual emails in the test environment, so you can
configure the environments that should be excluded like so:

    # config/initializers/resque_mailer.rb
    Sidekiq::Mailer.excluded_environments = [:test, :cucumber]

Note: Define `current_env` if using Sidekiq::Mailer in a non-Rails project:

    Resque::Mailer.current_env = :production


## Credits
This is project started with [resque_mailer](https://github.com/zapnap/resque_mailer) as a base, then migrated to a Sidekiq based system leveraging the built in ActionMailer delay extention
