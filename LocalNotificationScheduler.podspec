#
# Be sure to run `pod lib lint LocalNotificationScheduler.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LocalNotificationScheduler'
  s.version          = '1.0'
  s.summary          = 'LocalNotificationScheduler can be used to schedule local notification in iOS in a quick and easy way.'
s.swift_version = '4.2'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
LocalNotificationScheduler is an easier method to schedule local notifications in your project. It can schedule different types of local notifocations with one line of code.
                       DESC

  s.homepage         = 'https://github.com/FreshworksStudio/LocalNotificationScheduler.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'harishchopra86' => 'harish@freshworks.io' }
  s.source           = { :git => 'https://github.com/FreshworksStudio/LocalNotificationScheduler.git', :tag => 1.0 }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'LocalNotificationScheduler/Classes/**/*'
  
  # s.resource_bundles = {
  #   'LocalNotificationScheduler' => ['LocalNotificationScheduler/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
