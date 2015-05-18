require 'delayed_job'
require 'prowly'

class ProwlPlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.around(:invoke_job) do |job, *args, &block|
      begin
        block.call(job, *args)
      rescue Exception => error
        Prowly.notify do |n|
          n.apikey = ENV['PROWLY_KEY']
          n.application = "Policy Trainer"
          n.event = "Delayed Job Error"
          n.description = "#{error.class.name}: #{error.message}\n\nJob: #{job.inspect}"
        end
        raise error
      end
    end
  end
end

Delayed::Worker.plugins << ProwlPlugin
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.sleep_delay = 10
Delayed::Worker.read_ahead = 1
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
Delayed::Worker.delay_jobs = !Rails.env.test?
