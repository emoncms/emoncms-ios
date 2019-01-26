Pod::Spec.new do |spec|
  spec.name         = "Former"
  spec.version      = "1.7.0"
  spec.author       = { "ra1028" => "r.fe51028.r@gmail.com" }
  spec.homepage     = "https://github.com/ra1028"
  spec.summary      = "Former is a fully customizable Swift library for easy creating UITableView based form."
  spec.source       = { :git => "https://github.com/ra1028/Former.git", :tag => spec.version.to_s }
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.platform = :ios, '8.0'
  spec.source_files = "Former", "Former/**/*.{swift}"
  spec.requires_arc = true
  spec.ios.deployment_target = '8.0'
  spec.ios.frameworks = ['UIKit', 'Foundation']
end
