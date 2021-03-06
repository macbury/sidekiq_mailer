require "sidekiq_mailer/version"

module Sidekiq
  module Mailer
    class << self
      attr_accessor :default_queue_name, :current_env, :logger, :error_handler
      attr_reader :excluded_environments

      def excluded_environments=(envs)
        @excluded_environments = [*envs].map { |e| e.to_sym }
      end

      def included(base)
        base.extend(ClassMethods)
      end
    end

    self.logger ||= (defined?(::Rails) ? ::Rails.logger : nil)
    self.default_queue_name = "mailer"
    self.excluded_environments = [:test]

    module ClassMethods

      def current_env
        if defined?(Rails)
          ::Sidekiq::Mailer.current_env || ::Rails.env
        else
          ::Sidekiq::Mailer.current_env
        end
      end

      def method_missing(method_name, *args)
        if action_methods.include?(method_name.to_s)
          MessageDecoy.new(self, method_name, *args)
        else
          super
        end
      end

      def perform(action, *args)
        begin
          message = self.send(:new, action, *args).message
          message.deliver
        rescue Exception => ex
          if Mailer.error_handler
            if Mailer.error_handler.arity == 3
              warn "WARNING: error handlers with 3 arguments are deprecated and will be removed in the next release"
              Mailer.error_handler.call(self, message, ex)
            else
              Mailer.error_handler.call(self, message, ex, action, args)
            end
          else
            if logger
              logger.error "Unable to deliver email [#{action}]: #{ex}"
              logger.error ex.backtrace.join("\n\t")
            end

            raise ex
          end
        end
      end

      def queue
        @queue || ::Sidekiq::Mailer.default_queue_name
      end

      def queue=(name)
        @queue = name
      end

      def excluded_environment?(name)
        ::Sidekiq::Mailer.excluded_environments && ::Sidekiq::Mailer.excluded_environments.include?(name.try(:to_sym))
      end

      def deliver?
        true
      end
    end

    class MessageDecoy
      delegate :to_s, :to => :actual_message
      delegate :queue, :logger, to: :mailer_class

      attr_reader :mailer_class

      def initialize(mailer_class, method_name, *args)
        @mailer_class = mailer_class
        @method_name = method_name
        *@args = *args
        actual_message if environment_excluded?
      end

      def current_env
        if defined?(Rails)
          ::Sidekiq::Mailer.current_env || ::Rails.env
        else
          ::Sidekiq::Mailer.current_env
        end
      end

      def environment_excluded?
        !ActionMailer::Base.perform_deliveries || excluded_environment?(current_env)
      end

      def excluded_environment?(name)
        ::Sidekiq::Mailer.excluded_environments && ::Sidekiq::Mailer.excluded_environments.include?(name.try(:to_sym))
      end

      def actual_message
        @actual_message ||= @mailer_class.send(:new, @method_name, *@args).message
      end

      def deliver
        return deliver! if environment_excluded?

        if @mailer_class.deliver?
          begin
            # Use the ActionMailer delayed extension
            @mailer_class.delay.send(@method_name, @args)
          rescue Errno::ECONNREFUSED, Redis::CannotConnectError
            logger.error "Unable to connect to Redis; falling back to synchronous mail delivery" if logger
            deliver!
          end
        end
      end

      def deliver_at(time)
        raise NotImplementedError
      end

      def deliver_in(time)
        raise NotImplementedError
      end

      def unschedule_delivery
        raise NotImplementedError
      end

      def deliver!
        actual_message.deliver
      end

      def method_missing(method_name, *args)
        actual_message.send(method_name, *args)
      end
    end
  end
end
