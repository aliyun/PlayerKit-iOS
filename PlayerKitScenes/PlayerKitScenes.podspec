#
# Be sure to run `pod lib lint PlayerKitScenes.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PlayerKitScenes'
  s.version          = '1.0.0'
  s.summary          = 'AliPlayerKit iOS - Scene-based playback solutions'

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'PlayerKitScenes provides scene-based playback solutions including long video, short video and live streaming scenarios.'

  s.homepage         = 'https://aliyun.github.io/PlayerKit-iOS/'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'aliyunvideo' => 'videosdk@service.aliyun.com' }
  s.source           = { :git => 'https://github.com/aliyun/PlayerKit-iOS.git', :tag => "v#{s.version}" }

  s.ios.deployment_target = '9.0'
  s.static_framework = true

  s.default_subspecs = ['SceneLongVideo', 'SceneShortVideo', 'SceneLive', 'ScenePlaylist']

  # SceneCommon: Shared constants, utilities and resources across all scene modules.
  s.subspec 'SceneCommon' do |ss|
    ss.source_files = 'SceneCommon/Source/**/*.{h,m}'
    ss.public_header_files = 'SceneCommon/Source/**/*.h'
  end

  # SceneShortVideo: Short video hint page guiding users to the micro-drama solution.
  s.subspec 'SceneShortVideo' do |ss|
    ss.source_files = 'SceneShortVideo/Source/**/*.{h,m}'
    ss.public_header_files = 'SceneShortVideo/Source/**/*.h'
    ss.dependency 'PlayerKitScenes/SceneCommon'
  end

  # SceneLive: Live streaming playback scene with link configuration and QR scanning.
  s.subspec 'SceneLive' do |ss|
    ss.source_files = 'SceneLive/Source/**/*.{h,m}'
    ss.public_header_files = 'SceneLive/Source/**/*.h'
    ss.dependency 'PlayerKitScenes/SceneCommon'
    ss.dependency 'PlayerKit'
    ss.dependency 'DemoSettings'
  end

  # SceneLongVideo: Long video playback scene with full-screen player and progress control.
  s.subspec 'SceneLongVideo' do |ss|
    ss.source_files = 'SceneLongVideo/Source/**/*.{h,m}'
    ss.public_header_files = 'SceneLongVideo/Source/**/*.h'
    ss.dependency 'PlayerKitScenes/SceneCommon'
    ss.dependency 'PlayerKit'
  end

  # ScenePlaylist: Playlist scene with auto-advance playback using SingletonLifecycleStrategy.
  s.subspec 'ScenePlaylist' do |ss|
    ss.source_files = 'ScenePlaylist/Source/**/*.{h,m}'
    ss.public_header_files = 'ScenePlaylist/Source/**/*.h'
    ss.dependency 'PlayerKitScenes/SceneCommon'
    ss.dependency 'PlayerKit'
  end
end
