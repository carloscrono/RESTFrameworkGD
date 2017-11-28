Pod::Spec.new do |s|
  s.name = 'RESTFrameworkGD'
  s.version = '1.1'
  s.license = 'MIT'
  s.summary = 'RESTFramework utilizado para manejar peticiones HTTP'
  s.homepage = 'https://github.com/carloscrono/'
  s.social_media_url = ''
  s.authors = { 'Grupo GD' => 'cmartinez@grupogd.com.sv' }
  s.source = { :git => 'https://github.com/carloscrono/RESTFrameworkGD.git', :tag => s.version }

  s.ios.deployment_target = '10.0'

  s.source_files = 'Classes/**/*'
end
