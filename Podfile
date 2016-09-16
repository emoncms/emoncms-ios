source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'EmonCMSiOS' do
    pod 'Alamofire', '~> 4.0'

    pod 'RxSwift', '~> 3.0.0-beta.1'
    pod 'RxCocoa', '~> 3.0.0-beta.1'
    pod 'RxDataSources', '~> 1.0.0-beta.1'

    pod 'Locksmith', :git => 'https://github.com/fedetrim/Locksmith.git', branch: 'swift-3.0'

    pod 'Charts', :git => 'https://github.com/danielgindi/Charts.git', branch: 'Swift-3.0'
#    pod 'Charts/Realm', :git => 'https://github.com/danielgindi/Charts.git', branch: 'Swift-3.0'

#    pod 'Former', :git => 'https://github.com/ra1028/Former.git', branch: 'master'
    pod 'Former', :git => 'git@github.com:mattjgalloway/Former.git', branch: 'swift3'

    pod 'Realm', git: 'https://github.com/realm/realm-cocoa.git', branch: 'master', submodules: 'true'
    pod 'RealmSwift', git: 'https://github.com/realm/realm-cocoa.git', branch: 'master', submodules: 'true'
    pod 'RxRealm', git: 'https://github.com/ewerx/RxRealm.git', branch: 'swift-3.0'
end

target 'EmonCMSiOSTests' do
    pod 'Quick', :git => 'https://github.com/Quick/Quick.git', branch: 'swift-3.0'
    pod 'Nimble', :git => 'https://github.com/Quick/Nimble.git', branch: 'master'
    pod 'RxSwift', '~> 3.0.0-beta.1'
    pod 'RxCocoa', '~> 3.0.0-beta.1'
    pod 'RxTests', '~> 3.0.0-beta.1'
end

