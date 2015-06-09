require 'pathname'

run "rm README.rdoc;touch README.md"

add_source "http://rubygems.org"

gem 'puma'
gem 'auto_html'
gem 'devise'
gem 'stripe', github: 'stripe/stripe-ruby'
gem 'rb-fsevent', require: false
gem 'redis', '~> 3.0.1'
gem 'hiredis', '~> 0.4.5'
gem 'em-synchrony'
gem 'mailgun'
gem 'httparty'
gem 'prowly'
gem 'redis-objects'
gem 'carrierwave'
gem 'carrierwave_direct'
gem 'fog'
gem 'rack-cache'
gem 'pusher'
gem_group :development, :test do
  gem 'stripe-cli'
  gem 'rspec-rails'
  gem 'timecop'
  gem 'binding.repl'
  gem 'quiet_assets'
  gem 'coffee-rails-source-maps'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'database_cleaner'
  gem 'awesome_print'
  gem 'commands'
end
gem_group :production do
  gem 'rails_12factor'
  gem 'heroku_rails_deflate'
  gem 'heroku-deflater'
end

run "bundle install"

environment 'config.autoload_paths += Dir["#{config.root}/lib/**/"]
  config.time_zone = "Central Time (US & Canada)"
  config.encoding = "utf-8"
  config.filter_parameters += %i( password password_confirmation auth_token )
  config.active_support.escape_html_entities_in_json = false'

environment 'config.serve_static_assets = true
  config.assets.compress = true
  config.assets.compile = false
  config.force_ssl = true', env: 'production'

file '.bowerrc', <<-CONFIG
{
  "directory" : "vendor/assets/javascripts/bower_components"
}
CONFIG

file '.gitignore', <<-CONFIG
# Ignore bundler config.
/.bundle

# Ignore bower installed repos
/vendor/assets/javascripts/bower_components
/.bowerrc

# Ignore local stripe-cli config
/.stripecli

# Ignore the default SQLite database.
/db/*.sqlite3
/db/*.sqlite3-journal

# Ignore various redis store files
/db/redis

# Ignore all logfiles and tempfiles.
/log/*.log
/tmp
CONFIG

file 'Procfile', <<-CODE
  web: bundle exec puma -t ${PUMA_MIN_THREADS:-8}:${PUMA_MAX_THREADS:-12} -w ${PUMA_WORKERS:-2} -p $PORT -e ${RACK_ENV:-production}
CODE

file 'redis.conf', <<-CODE
timeout 0
databases 10
daemonize yes
pidfile './tmp/pids/redis.pid'
save 900 1
save 300 10
save 60 1000
dir '#{ENV['HOME']}/CODE/db/redis-stores/#{Pathname.pwd.basename}/dev'
maxmemory-policy noeviction
appendonly yes
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
aof-rewrite-incremental-fsync yes
CODE

lib 'nest.rb' do
<<-NEST
require 'redis'
class Nest < String
  VERSION = "1.1.0"

  METHODS = [ :append, :blpop, :brpop, :brpoplpush, :decr, :decrby,
  :del, :exists, :expire, :expireat, :get, :getbit, :getrange, :getset,
  :hdel, :hexists, :hget, :hgetall, :hincrby, :hkeys, :hlen, :hmget,
  :hmset, :hset, :hsetnx, :hvals, :incr, :incrby, :lindex, :linsert,
  :llen, :lpop, :lpush, :lpushx, :lrange, :lrem, :lset, :ltrim, :move,
  :persist, :publish, :rename, :renamenx, :rpop, :rpoplpush, :rpush,
  :rpushx, :sadd, :scard, :sdiff, :sdiffstore, :set, :setbit, :setex,
  :setnx, :setrange, :sinter, :sinterstore, :sismember, :smembers,
  :smove, :sort, :spop, :srandmember, :srem, :strlen, :subscribe,
  :sunion, :sunionstore, :ttl, :type, :unsubscribe, :watch, :zadd,
  :zcard, :zcount, :zincrby, :zinterstore, :zrange, :zrangebyscore,
  :zrank, :zrem, :zremrangebyrank, :zremrangebyscore, :zrevrange,
  :zrevrangebyscore, :zrevrank, :zscore, :zunionstore ]

  attr :redis

  def initialize key, redis = Redis.current
    key = key.to_redis_key if key.respond_to?( :to_redis_key )
    super key
    @redis = redis
  end

  def [] key
    key = key.to_redis_key if key.respond_to?( :to_redis_key )
    self.class.new "\#{self}:\#{key}", redis
  end

  METHODS.each do |meth|
    define_method meth do |*args, &block|
      redis.send meth, self, *args, &block
    end
  end
end
NEST
end

rakefile 'autohtml.rake' do
<<-TASK
require 'auto_html'

module AutoHtml
  module Task
    def self.obtain_class
      class_name = ENV['CLASS'] || ENV['class']
      raise "Must specify CLASS" unless class_name
      class_name
    end
  end
end
namespace :auto_html do
  desc "Rebuild auto_html columns"
  task rebuild: :environment do

    klass  = AutoHtml::Task.obtain_class.constantize
    suffix = AutoHtmlFor.auto_html_for_options[:htmlized_attribute_suffix]
    column_names = klass.respond_to?(:column_names) ? klass.column_names : klass.fields.keys
    observed_attributes = column_names.select { |c| c=~/\#{suffix}$/ }.map { |c| c.gsub(/\#{suffix}$/, '')}

    i = 0
    klass.find_each do |item|
      observed_attributes.each do |field|
        item.send("\#{field}=", item.send(field))
      end
      item.save
      i += 1
    end

    puts "Done! Processed \#{i} items."
  end
end
TASK
end

rakefile 'schema_ref.rake' do
<<-TASK
ENV['NOT_ARRAYS'] ||= "status"

module SchemaGen
  module Utils
    def self.path_to klass
      File.expand_path("./app/models/\#{klass.name.underscore}.rb")
    end

    def self.length_of_longest_field_name klass
      klass.columns_hash.keys.max_by(&:length).length.to_i + 1
    end

    def self.type_text_or_integer_and_ends_with_s? key, val
      (val.type.to_s == "text" || val.type.to_s == "integer") &&
      key.to_s.ends_with?("s") && !key.to_s.in?(not_arrays)
    end

    def self.type_string_and_ends_with_types? key, val
      val.type.to_s == "string" && (key.to_s.ends_with?("types") || key.to_s.ends_with?("keys")) && !key.to_s.in?(not_arrays)
    end

    def self.not_arrays
      ENV['NOT_ARRAYS'].split(",").map(&:strip)
    end
  end
end

namespace :gen do
  desc "Generate a Schema Reference in comments at the end of every ActiveRecord Model Class definition"
  task model_schema: :environment do
    Rails.application.eager_load!
    ActiveRecord::Base.subclasses.each do |klass|
      next if "\#{klass}" == "Delayed::Backend::ActiveRecord::Job"
      max_length = SchemaGen::Utils.length_of_longest_field_name(klass)
      column_desc = klass.columns_hash.each_with_object("## Database Schema\n#\n") do |(key,val),tmp|
        value =
        SchemaGen::Utils.type_text_or_integer_and_ends_with_s?(key,val) ? "array of \#{val.type}s" :
        SchemaGen::Utils.type_string_and_ends_with_types?(key,val) ? "array of strings" : val.type
        tmp<<"# %-*s: %s\n" % [max_length,key,value]
      end
      File.open( SchemaGen::Utils.path_to(klass), 'r+' ) do |file|
        if length = file.read.rindex(/^##\sDatabase\sSchema$/m)
          file.rewind
          file.truncate(length)
        end
        file.read
        file.write column_desc
      end
      puts "%-*s schema generated" % [17,klass.name]
    end
  end

end
TASK
end


vendor_js = Pathname('~/CODE/Templates/rails-project/javascripts/vendor').expand_path.children
inside 'vendor/assets/javascripts' do
  run 'mkdir bower_components'
  file 'bower_components/index.js.coffee', "## Reference Component Main Files Here\n\n"
  vendor_js.each do |js|
    run "cp #{js.to_path} #{js.basename}"
  end
end

vendor_css = Pathname('~/CODE/Templates/rails-project/stylesheets/vendor').expand_path.children
inside 'vendor/assets/stylesheets' do
  vendor_css.each do |css|
    run "cp #{css.to_path} #{css.basename}"
  end
end

lib_css = Pathname('~/CODE/Templates/rails-project/stylesheets/lib').expand_path.children
inside 'lib/assets' do
  run 'mkdir stylesheets'
  lib_css.each do |css|
    run "cp #{css.to_path} stylesheets/#{css.basename}"
  end
end

app_css = Pathname('~/CODE/Templates/rails-project/stylesheets/application.css.scss').expand_path
inside 'app/assets/stylesheets' do
  run "rm application.css"
  run "cp #{app_css.to_path} #{app_css.basename}"
end

app_js = Pathname('~/CODE/Templates/rails-project/javascripts/application.js.coffee').expand_path
inside 'app/assets/javascripts' do
  run "rm application.js"
  run "cp #{app_js.to_path} #{app_js.basename}"
end

app_layout = Pathname('~/CODE/Templates/rails-project/views/app-layout.html.erb').expand_path
inside 'app/views/layouts' do
  run "rm application.html.erb"
  run "cp #{app_layout.to_path} application.html.erb"
end

shared_views = Pathname('~/CODE/Templates/rails-project/views/shared').expand_path.children
inside 'app/views' do
  run "mkdir application"
  run "touch application/index.html.erb"
  run "mkdir shared"
  shared_views.each do |view|
    run "cp #{view.to_path} shared/#{view.basename}"
  end
end

Pathname('~/CODE/Templates/rails-project/initializers').expand_path.children.each do |file|
  initializer file.basename, file.read
end

inside 'app/controllers' do
  run "rm application_controller.rb"
  run "cp ~/CODE/Templates/rails-project/controllers/application_controller.rb application_controller.rb"
end

route "root to: 'application#index'"

run "rake db:create db:migrate"

git :init
git commit: "-am 'Initial commit'"

if yes? "add upstream github repo as `origin` ? [Yn]"
  repo_path = ask("please provide origin repo url:")
  git remote: "add origin #{repo_path}"
  git push: "-u origin master"
end