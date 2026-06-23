#
# Be sure to run `pod lib lint PlayerKitUsages.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PlayerKitUsages'
  s.version          = '1.0.0'
  s.summary          = 'AliPlayerKit iOS - Usage examples for PlayerKit features'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'PlayerKitUsages provides usage examples and integration guides for PlayerKit features including log system, event system, and more.'

  s.homepage         = 'https://aliyun.github.io/PlayerKit-iOS/'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'aliyunvideo' => 'videosdk@service.aliyun.com' }
  s.source           = { :git => 'https://github.com/aliyun/PlayerKit-iOS.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '9.0'
  s.static_framework = true

  s.default_subspecs = ['UsageVideoSource', 'UsageLogSystem', 'UsageSlotSystem', 'UsageNotificationSystem', 'UsageStrategySystem', 'UsageLocaleSystem', 'UsageLifecycleStrategy', 'UsagePreloadSystem']

  # UsageCommon: Shared constants and utilities across all usage example modules.
  s.subspec 'UsageCommon' do |ss|
    ss.source_files = 'UsageCommon/Source/**/*.{h,m}'
    ss.public_header_files = 'UsageCommon/Source/**/*.h'
  end

  # UsageVideoSource: Usage examples for PlayerKit video source types.
  s.subspec 'UsageVideoSource' do |ss|
    ss.source_files = 'UsageVideoSource/Source/**/*.{h,m}'
    ss.public_header_files = 'UsageVideoSource/Source/**/*.h'
    ss.dependency 'PlayerKitUsages/UsageCommon'
    ss.dependency 'PlayerKit'
    ss.dependency 'PlayerKitScenes/SceneCommon'
    ss.dependency 'DemoSettings'
  end

  # UsageLogSystem: Usage examples for PlayerKit log system integration.
  s.subspec 'UsageLogSystem' do |ss|
    ss.source_files = 'UsageLogSystem/Source/**/*.{h,m}'
    ss.public_header_files = 'UsageLogSystem/Source/**/*.h'
    ss.dependency 'PlayerKitUsages/UsageCommon'
    ss.dependency 'PlayerKit'
    ss.dependency 'PlayerKitScenes/SceneCommon'
  end

  # UsageSlotSystem: Usage examples for PlayerKit slot system integration.
  s.subspec 'UsageSlotSystem' do |ss|
    ss.source_files = 'UsageSlotSystem/Source/**/*.{h,m}'
    ss.public_header_files = 'UsageSlotSystem/Source/**/*.h'
    ss.dependency 'PlayerKitUsages/UsageCommon'
    ss.dependency 'PlayerKit'
    ss.dependency 'PlayerKitScenes/SceneCommon'
  end

  # UsageNotificationSystem: Usage examples for PlayerKit notification system integration.
  s.subspec 'UsageNotificationSystem' do |ss|
    ss.source_files = 'UsageNotificationSystem/Source/**/*.{h,m,mm}'
    ss.public_header_files = 'UsageNotificationSystem/Source/**/*.h'
    ss.dependency 'PlayerKitUsages/UsageCommon'
    ss.dependency 'PlayerKit'
    ss.dependency 'PlayerKitScenes/SceneCommon'
  end

  # UsageStrategySystem: Usage examples for PlayerKit strategy system integration.
  s.subspec 'UsageStrategySystem' do |ss|
    ss.source_files = 'UsageStrategySystem/Source/**/*.{h,m}'
    ss.public_header_files = 'UsageStrategySystem/Source/**/*.h'
    ss.dependency 'PlayerKitUsages/UsageCommon'
    ss.dependency 'PlayerKit'
    ss.dependency 'PlayerKitScenes/SceneCommon'
  end

  # UsageLocaleSystem: Usage examples for PlayerKit locale system integration.
  s.subspec 'UsageLocaleSystem' do |ss|
    ss.source_files = 'UsageLocaleSystem/Source/**/*.{h,m}'
    ss.public_header_files = 'UsageLocaleSystem/Source/**/*.h'
    ss.dependency 'PlayerKitUsages/UsageCommon'
    ss.dependency 'PlayerKit'
    ss.dependency 'PlayerKitScenes/SceneCommon'
  end

  # UsageLifecycleStrategy: Usage examples for PlayerKit lifecycle strategy integration.
  s.subspec 'UsageLifecycleStrategy' do |ss|
    ss.source_files = 'UsageLifecycleStrategy/Source/**/*.{h,m}'
    ss.public_header_files = 'UsageLifecycleStrategy/Source/**/*.h'
    ss.dependency 'PlayerKitUsages/UsageCommon'
    ss.dependency 'PlayerKit'
    ss.dependency 'PlayerKitScenes/SceneCommon'
  end

  # UsagePreloadSystem: Usage examples for PlayerKit preload system integration.
  s.subspec 'UsagePreloadSystem' do |ss|
    ss.source_files = 'UsagePreloadSystem/Source/**/*.{h,m}'
    ss.public_header_files = 'UsagePreloadSystem/Source/**/*.h'
    ss.dependency 'PlayerKitUsages/UsageCommon'
    ss.dependency 'PlayerKit'
    ss.dependency 'PlayerKitScenes/SceneCommon'
  end

end
