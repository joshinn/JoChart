
Pod::Spec.new do |s|

  s.name         = "JoChart"
  s.version      = "0.16"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.summary      = "Jo chart is a swift library for drawing chart"
  s.author       = { "joshin" => "xjcute@gmail.com" }
  s.homepage     = "https://github.com/joshinn/JoChart"
  s.description  = <<-DESC
                      a swift library for drawing chart, developing
                    DESC
  s.requires_arc = true
  s.platform     = :ios, "12.0"
  s.frameworks   = 'UIKit', 'Metal'
  s.swift_version = '5.0'

  s.source       = { :git => "https://github.com/joshinn/JoChart.git", :tag => s.version.to_s }
  s.source_files  = "chart/**/*.*"

end
