dir = File.dirname(File.expand_path(__FILE__))
$LOAD_PATH.unshift dir + '/../lib'
$TESTING = true

gem 'minitest'
require 'minitest/unit'
require 'minitest/pride'
require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
end

require 'resque-lock-timeout'
require dir + '/test_jobs'

# make sure we can run redis
if !system('which redis-server')
  puts '', "** can't find `redis-server` in your path"
  puts '** try running `sudo rake install`'
  abort ''
end

# start our own redis when the tests start,
# kill it when they end
at_exit do
  next if $!

  exit_code = MiniTest::Unit.new.run(ARGV)

  pid = `ps -e -o pid,command | grep [r]edis-test`.split(' ')[0]
  puts 'Killing test redis server...'
  `rm -f #{dir}/dump.rdb`
  Process.kill('KILL', pid.to_i)
  exit exit_code
end

puts 'Starting redis for testing at localhost:9736...'
`redis-server #{dir}/redis-test.conf`
Resque.redis = '127.0.0.1:9736'