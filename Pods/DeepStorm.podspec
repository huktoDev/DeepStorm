#
#  Be sure to run `pod spec lint DeepStorm.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = 'DeepStorm'
  spec.version      = '1.0.6'
  spec.summary      = 'DeepStorm provides Logging, Journalling, Reporting and Module/Service Management'



  spec.description  = <<-DESC
	DeepStorm is a powerful extraordinary obj-c Library for 
	Logging, Journalling, Reporting & Module/Service Management
                   DESC

  spec.homepage     = 'https://github.com/huktoDev/DeepStorm'

  spec.license      = { :type => 'Apache License, Version 2.0', :file => 'LICENSE.txt'}

  spec.author             = { 'Alexandr Babenko (HuktoDev)' => 'hikto583004@list.ru' }
  spec.social_media_url   = 'http://vk.com/hukto777'
  spec.platform     = :ios, '7.0'
  spec.source       = { :git => 'https://github.com/huktoDev/DeepStorm.git', :tag => '1.0.0' }

  spec.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  spec.frameworks = 'MessageUI', 'UIKit'

  spec.source_files = 'ReporterProject/DeepStorm/**/*.*'
  spec.exclude_files = ['ReporterProject/DeepStorm/DSIdeaHeader.h']
  spec.public_header_files = 'ReporterProject/DeepStorm/**/*.h'

# 'ReporterProject/DeepStorm/Reporting/Custom Reporters/Email Reporters/DSEmailHiddenReporter.*'

  spec.dependency 'GDataXML-HTML', '~> 1.3.0'
  spec.dependency 'mailcore2-ios'
  
  spec.ios.vendored_libraries = 'libMailCore-ios.a'
  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # s.framework  = "SomeFramework"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  #spec.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
