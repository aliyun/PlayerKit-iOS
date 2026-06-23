#
# Be sure to run `pod lib lint App.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PlayerKit'
  s.version          = '1.0.0'
  s.summary          = 'AliPlayerKit iOS - Low-code player UI components'
  
  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  
  s.description      = 'AliPlayerKit iOS provides ready-to-use player UI components and scene-based solutions'
  
  s.homepage         = 'https://aliyun.github.io/PlayerKit-iOS/'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'aliyunvideo' => 'videosdk@service.aliyun.com' }
  s.source           = { :git => 'https://github.com/aliyun/PlayerKit-iOS.git', :tag => "v#{s.version}" }
  
  s.ios.deployment_target = '9.0'
  s.static_framework = true
  
  s.source_files = 'Source/**/*.{h,m,mm}'
  s.resource = 'Resources/PlayerKit.bundle'
  s.public_header_files = 'Source/**/*.h'
  s.private_header_files = 'Source/**/*+Private.h'
  
  s.dependency 'AliPlayerSDK_iOS'
  
  # 第三方库：异步图片加载与缓存（用于封面图等场景）
  s.dependency 'SDWebImage', '5.18.1'
end
