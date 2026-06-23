#
# Be sure to run `pod lib lint DemoSettings.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DemoSettings'
  s.version          = '1.0.0'
  s.summary          = 'PlayerKit-iOS Demo Settings - App-level configuration and link management'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Demo settings module providing persistent storage, link configuration with QR scanning for PlayerKit demo app.'

  s.homepage         = 'https://aliyun.github.io/PlayerKit-iOS/'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'aliyunvideo' => 'videosdk@service.aliyun.com' }
  s.source           = { :git => 'https://github.com/aliyun/PlayerKit-iOS.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '9.0'
  s.static_framework = true

  s.source_files = 'Source/**/*.{h,m}'
  s.public_header_files = 'Source/**/*.h'
  s.frameworks = 'AVFoundation'
  s.dependency 'PlayerKit'
end
