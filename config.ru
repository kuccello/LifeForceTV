require 'rubygems'
require 'xampl'
require 'haml'
require 'rack-flash'

require ::File.join(::File.dirname(__FILE__), 'utils/string')

$LIFEFORCE_INSTALLED = false
$SITE_NAME = "LifeForceTV"
$TRANSACTION_CONTEXT = "lifeforce"
$LIFEFORCE_VERSION = "6.0"
$lifeforce_configuration_setup_flag = true

$LIFEFORCE_INSTALLED = ::File.exist?(::File.dirname(__FILE__)+"/installed.rb")
puts "Is #{$SITE_NAME} installed?: #{$LIFEFORCE_INSTALLED}"
if $LIFEFORCE_INSTALLED then
  require ::File.join(::File.dirname(__FILE__), "installed" )
end

require ::File.join(::File.dirname(__FILE__), 'model/init')

require ::File.join(::File.dirname(__FILE__), 'administration/admin')
require ::File.join(::File.dirname(__FILE__), 'site/site')
require ::File.join(::File.dirname(__FILE__), 'adservice/adservice')
require ::File.join(::File.dirname(__FILE__), 'setup/setup')


use Rack::Session::Pool, :expire_after => 60 * 30 #60 * 60 * 24 * 365
use Rack::Flash

map '/' do
  run LifeForceSite
end

map '/admin' do
  run LifeForceAdmin
end

map '/ads' do
  run LifeForceAdService
end

map '/setup' do
  run LifeForceSetup
end
