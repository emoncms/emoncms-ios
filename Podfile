source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

def shared_pods
    pod 'RxSwift', '~> 4.4'
    pod 'RxCocoa', '~> 4.4'
    pod 'RxDataSources', '~> 3.1'
    pod 'Realm', '~> 3.13'
    pod 'RealmSwift', '~> 3.13'
end

def shared_app_pods
    pod 'XCGLogger', '~> 6.1'
    pod 'Locksmith', '~> 4.0'
    pod 'RxRealm', '~> 0.7'
end

target 'EmonCMSiOS' do
    platform :ios, '11.0'
    shared_pods
    shared_app_pods

    pod 'Action', '~> 3.9'
    pod 'Charts', '~> 3.2'
    pod 'Former', '~> 1.7'

    post_install do | installer |
        require 'fileutils'
        FileUtils.cp_r('Pods/Target Support Files/Pods-EmonCMSiOS/Pods-EmonCMSiOS-acknowledgements.plist', 'EmonCMSiOS/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
    end
end

def testing_pods
    pod 'Quick', '~> 1.3'
    pod 'Nimble', '~> 7.3'
    pod 'RxTest', '~> 4.4'
end

target 'EmonCMSiOSTests' do
    platform :ios, '11.0'
    shared_pods
    testing_pods
end

target 'EmonCMSiOSUITests' do
    platform :ios, '11.0'
    shared_pods
    testing_pods
end
