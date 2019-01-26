Changelog
=========

1.4.0
-----
- New observable `appVersion` that emits your app's previous and current version string each time the user opens the app
- `firstLaunchOfNewVersionOnly` now emits an `AppVersion` object that contains the previous and the current app version string (thanks to [Ashton Meuser](https://github.com/ashtonmeuser) for suggesting that change!)

1.3.0
-----
- App open counts and app versions are now tracked even if there is no subscription to the relevant Observables  (thanks to [Philippe Cuvillier](https://github.com/PhilippeCuvillier) for suggesting that change!)

1.2.0
-----
- updates to Swift 4.2
- removes obsolete `Equatable` implementation (thanks to [Pavel Sorokin](https://github.com/NeverwinterMoon) for the contribution)
- removes all calls to `UserDefaults.standard.synchronize()` (thanks again to [Pavel Sorokin](https://github.com/NeverwinterMoon) for pointing that out)

1.1.2
-----
- updates to Swift 4.1
- fixes an issue with Carthage compatibility

1.1.1
-----
- fixes issue [#13](https://github.com/pixeldock/RxAppState/issues/13) where `firstLaunchOfNewVersionOnly` would not emit events correctly. Thanks to [ptigro89](https://github.com/ptigro89) for finding that bug!

1.1.0
-----
- add observables for `viewDidLoad` and `viewDidLayoutSubviews` (thanks to [ivanmkc](https://github.com/ivanmkc) for the contribution)
- update example to show more UIViewController view states

1.0.1
-----
- add observable for `applicationWillEnterForeground` (thanks to [pepasflo](https://github.com/pepasflo) for the contribution)
- fix deployment target for Carthage usage

1.0.0
-----
- add Observables for UIViewController's view-related notifications
- allow multiple subscriptions to Observables that use UserDefaults (thanks to [junmo-kim](https://github.com/junmo-kim) for the contribution)

0.4.0
-----
- update RxSwift / RxCocoa dependency to 4.0
- update to Swift 4.0 (thanks to [pual](https://github.com/pual) for requesting a crucial change in RxSwift 4)

0.3.4
-----
- update RxSwift / RxCocoa dependency to 3.4

0.3.3
-----
- update RxSwift / RxCocoa dependency to 3.3
- update to Swift 3.1

0.3.1
-----
- bugfix in `isFirstLaunchOfNewVersion` (fixed by [krider2010](https://github.com/krider2010))
- update RxSwift / RxCocoa dependency to 3.1

0.3.0
-----
- update to Swift 3.0
- update RxSwift / RxCocoa dependency to 3.0
- use Reactive proxy
- add `isFirstLaunchOfNewVersion` (contribution by [krider2010](https://github.com/krider2010))

0.2.0
-----
- update to Swift 2.3

0.1.1
-----
- update RxSwift / RxCocoa dependency to 2.6
- fix deprecation warnings
- update iOS and Xcode version in .travis.yml file

0.1.0
-----
- Initial release
