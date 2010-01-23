require 'rubygems'
require 'xampl'
require 'haml'
require 'rack-flash'
require 'chronic'
require 'mcnamara'

require ::File.join(::File.dirname(__FILE__), 'utils/string')

$DEFAULT_DESC = "Canada's online broadcast network showcasing original web series created by Canada's top internet producers. Lifeforcetv.com is a new way to enjoy television with no required subscription, fees, or territory restrictions."
$DEFAULT_KEY = "canadian web series, canadian web shows, online video, canada's online broadcast network, lifeforcetv, lifeforce, shows, canada, filmmakers, tv, entertainment, episodes, watch"
$DEFAULT_TITLE = "LifeForceTV - Canada's online broadcast network"

$DESCRIPTION = $DEFAULT_DESC
$KEYWORDS = $DEFAULT_KEY
$TITLE = $DEFAULT_TITLE

$LIFEFORCE_INSTALLED = false
$SITE_NAME = "LifeForceTV"
$TRANSACTION_CONTEXT = "lifeforce"
$LIFEFORCE_VERSION = "6.1"
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
