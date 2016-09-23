source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

def shared_pods
    pod 'RxSwift', '~> 3.0.0-beta.1'
    pod 'RxCocoa', '~> 3.0.0-beta.1'
    pod 'Realm', '~> 1.1'
    pod 'RealmSwift', '~> 1.1'
end

target 'EmonCMSiOS' do
    platform :ios, '10.0'
    shared_pods

    pod 'Alamofire', '~> 4.0'

    pod 'RxDataSources', '~> 1.0.0-beta.1'

    pod 'Locksmith', '~> 3.0'

    pod 'Charts', :git => 'https://github.com/danielgindi/Charts.git', branch: 'Swift-3.0'
#    pod 'Charts/Realm', :git => 'https://github.com/danielgindi/Charts.git', branch: 'Swift-3.0'

#    pod 'Former', :git => 'https://github.com/ra1028/Former.git', branch: 'master'
    pod 'Former', :git => 'git@github.com:mattjgalloway/Former.git', branch: 'swift3'

    pod 'RxRealm', '~> 0.2'
end

target 'EmonCMSiOSTests' do
    platform :ios, '10.0'
    shared_pods
    pod 'Quick', :git => 'https://github.com/Quick/Quick.git', branch: 'swift-3.0'
    pod 'Nimble', :git => 'https://github.com/Quick/Nimble.git', branch: 'master'
    pod 'RxTests', '~> 3.0.0-beta.1'
end

target 'EmonCMSWatch Extension' do
    platform :watchos, '2.0'
    shared_pods
end
