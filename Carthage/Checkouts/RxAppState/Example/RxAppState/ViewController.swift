//
//  ViewController.swift
//  RxAppState
//
//  Created by Jörn Schoppe on 03/06/2016.
//  Copyright (c) 2016 Jörn Schoppe. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxAppState

class ViewController: UIViewController {
    
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var firstLaunchLabel: UILabel!
    @IBOutlet weak var previousVersionLabel: UILabel!
    @IBOutlet weak var currentVersionLabel: UILabel!
    @IBOutlet weak var appOpenedLabel: UILabel!
    @IBOutlet weak var firstLaunchAfterUpdateLabel: UILabel!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var simulateUpdateButton: UIButton!
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupExampleUI()
        
        let application = UIApplication.shared
        
        /**
        Show the application state
        */
        application.rx.appState
            .bind(to: stateLabel.rx_appState)
            .disposed(by: disposeBag)
        
        /**
        Show if the app is launched for the first time
        */
        application.rx.isFirstLaunch
            .bind(to: firstLaunchLabel.rx_firstLaunch)
            .disposed(by: disposeBag)
        
        /**
        Show how many times the app has been opened
        */
        application.rx.didOpenAppCount
            .subscribe(onNext: { count in
                self.appOpenedLabel.text = count == 1 ? "1 time" : "\(count) times"
            })
            .disposed(by: disposeBag)
        
        /**
         Show previous app version
         */
        application.rx.appVersion
            .map { $0.previous }
            .bind(to: previousVersionLabel.rx.text)
            .disposed(by: disposeBag)
        
        /**
         Show current app version
         */
        application.rx.appVersion
            .map { $0.current }
            .bind(to: currentVersionLabel.rx.text)
            .disposed(by: disposeBag)
        
        /**
         Show if the app is launched for the first time after an update
         */
        application.rx.isFirstLaunchOfNewVersion
            .bind(to: firstLaunchAfterUpdateLabel.rx_firstLaunch)
            .disposed(by: disposeBag)
    }
    
    func setupExampleUI() {
        appVersionLabel.text = RxAppState.currentAppVersion
        
        simulateUpdateButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.simulateAppUpdate()
            })
            .disposed(by: disposeBag)
    }
    
    func simulateAppUpdate() {
        guard let currentMinorVersion = RxAppState.currentAppVersion?.components(separatedBy: ".").last else { return }
        let minorVersion = Int(currentMinorVersion) ?? 0
        let newSimulatedAppVersion = "1.\(minorVersion + 1)"
        RxAppState.currentAppVersion = newSimulatedAppVersion
        appVersionLabel.text = newSimulatedAppVersion
    }
}
	
