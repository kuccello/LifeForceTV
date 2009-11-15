require 'rubygems'
require 'xampl'
require 'haml'
require 'rack-flash'

require ::File.join(::File.dirname(__FILE__), 'utils/string')

require ::File.join(::File.dirname(__FILE__), 'model/init')

require ::File.join(::File.dirname(__FILE__), 'administration/admin')
require ::File.join(::File.dirname(__FILE__), 'site/site')
require ::File.join(::File.dirname(__FILE__), 'adservice/adservice')

$SITE_NAME = "LifeForceTV"
$TRANSACTION_CONTEXT = "lifeforce"

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
