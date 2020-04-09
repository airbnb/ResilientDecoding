Pod::Spec.new do |s|
  s.name     = 'ResilientDecoding'
  s.version  = '0.9.1'
  s.license  = 'MIT'
  s.summary  = 'A cache that enables the performant persistence of individual messages to disk'
  s.homepage = 'https://github.com/airbnb/ResilientDecoding'
  s.authors  = 'George Leontiev'
  s.source   = { :git => 'https://github.com/airbnb/ResilientDecoding.git', :tag => s.version }
  s.swift_version = '5.1'
  s.source_files = 'Sources/ResilientDecoding/**/*.{swift}'
  s.ios.deployment_target = '12.0'
  s.tvos.deployment_target = '12.0'
  s.watchos.deployment_target = '5.0'
  s.macos.deployment_target = '10.14'
end
