ENV['APP_MODE'] ||= ENV['RAILS_ENV']=="production" ? 'live' : 'test'

module AppMode
  def self.live?
    !!ENV['APP_MODE']=='live'
  end
end