#
# Be sure to run `pod lib lint JSAsyncExecution.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JSAsyncExecution'
  s.version          = '0.1.0'
  s.summary          = 'Async Execution At Background'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
这是一个阅读YYWebImage源码后，封装的一个异步执行工具，
                       DESC

  s.homepage         = 'https://space.bilibili.com/600175291?spm_id_from=333.1007.0.0'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Json' => '1595371165@qq.com' }
  s.source           = { :git => 'https://github.com/json1994/JSAsyncExecution.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '11.0'

  s.source_files = 'JSAsyncExecution/Classes/**/*'
  
  # s.resource_bundles = {
  #   'JSAsyncExecution' => ['JSAsyncExecution/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
