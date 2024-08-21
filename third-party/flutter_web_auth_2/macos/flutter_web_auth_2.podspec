#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_web_auth_2.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
s.name             = 'flutter_web_auth_2'
s.version          = '3.0.0'
s.summary          = 'A new Flutter plugin project.'
s.description      = <<-DESC
        A new Flutter plugin project.
DESC
        s.homepage         = 'http://example.com'
s.license          = { :file => '../LICENSE' }
s.author           = { 'Your Company' => 'email@example.com' }

s.source           = { :path => '.' }
s.source_files     = 'Classes/**/*'
s.dependency 'FlutterMacOS'

s.platform = :osx, '10.15'
s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
s.swift_version = '5.0'
end
