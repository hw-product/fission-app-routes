$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'fission-app-routes/version'
Gem::Specification.new do |s|
  s.name = 'fission-app-routes'
  s.version = FissionApp::Routes::VERSION.version
  s.summary = 'Fission App Routes'
  s.author = 'Heavywater'
  s.email = 'fission@hw-ops.com'
  s.homepage = 'http://github.com/hw-product/fission-app-routes'
  s.description = 'Fission backend route configuration UI'
  s.require_path = 'lib'
  s.add_dependency 'fission-data'
  s.add_dependency 'fission-app'
  s.files = Dir['{lib,app,config}/**/**/*'] + %w(fission-app-routes.gemspec README.md CHANGELOG.md)
end
