//
//  RxAppStateVCTests.swift
//  RxAppState_ExampleTests
//
//  Created by Jörn Schoppe on 31.10.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import XCTest
@testable import RxAppState_Example
import RxSwift
import RxCocoa
import RxAppState

class RxAppStateVCTests: XCTestCase {
    
    let viewController = UIViewController()
    let disposeBag = DisposeBag()
    
    func testViewDidLoad() {
        // Given
        var didCallViewDidLoad: Bool = false
        viewController.rx.viewDidLoad
            .subscribe(onNext: {  _ in
                didCallViewDidLoad = true
            })
            .disposed(by: disposeBag)
        
        // When
        viewController.viewDidLoad()
        
        // Then
        XCTAssertEqual(didCallViewDidLoad, true)
    }
    
    func testViewDidLayoutSubviews() {
        // Given
        var didCallViewDidLayoutSubviews: Bool = false
        viewController.rx.viewDidLayoutSubviews
            .subscribe(onNext: {  _ in
                didCallViewDidLayoutSubviews = true
            })
            .disposed(by: disposeBag)
        
        // When
        viewController.viewDidLayoutSubviews()
        
        // Then
        XCTAssertEqual(didCallViewDidLayoutSubviews, true)
    }
    
    func testViewWillAppear() {
        // Given
        var didCallViewWillAppear: Bool?
        viewController.rx.viewWillAppear
            .subscribe(onNext: {  animated in
                didCallViewWillAppear = animated
            })
            .disposed(by: disposeBag)
        
        // When
        viewController.viewWillAppear(false)
        
        // Then
        XCTAssertEqual(didCallViewWillAppear, false)
    }
    
    func testViewWillAppearAnimated() {
        // Given
        var didCallViewWillAppear: Bool?
        viewController.rx.viewWillAppear
            .subscribe(onNext: {  animated in
                didCallViewWillAppear = animated
            })
            .disposed(by: disposeBag)
        
        // When
        viewController.viewWillAppear(true)
        
        // Then
        XCTAssertEqual(didCallViewWillAppear, true)
    }
    
    func testViewDidAppear() {
        // Given
        var didCallViewDidAppear: Bool?
        viewController.rx.viewDidAppear
            .subscribe(onNext: {  animated in
                didCallViewDidAppear = animated
            })
            .disposed(by: disposeBag)
        
        // When
        viewController.viewDidAppear(false)
        
        // Then
        XCTAssertEqual(didCallViewDidAppear, false)
    }
    
    func testViewDidAppearAnimated() {
        // Given
        var didCallViewDidAppear: Bool?
        viewController.rx.viewDidAppear
            .subscribe(onNext: {  animated in
                didCallViewDidAppear = animated
            })
            .disposed(by: disposeBag)
        
        // When
        viewController.viewDidAppear(true)
        
        // Then
        XCTAssertEqual(didCallViewDidAppear, true)
    }
    
    func testViewWillDisappear() {
        // Given
        var didCallViewWillDisappear: Bool?
        viewController.rx.viewWillDisappear
            .subscribe(onNext: {  animated in
                didCallViewWillDisappear = animated
            })
            .disposed(by: disposeBag)
        
        // When
        viewController.viewWillDisappear(false)
        
        // Then
        XCTAssertEqual(didCallViewWillDisappear, false)
    }
    
    func testViewWillDisappearAnimated() {
        // Given
        var didCallViewWillDisappear: Bool?
        viewController.rx.viewWillDisappear
            .subscribe(onNext: {  animated in
                didCallViewWillDisappear = animated
            })
            .disposed(by: disposeBag)
        
        // When
        viewController.viewWillDisappear(true)
        
        // Then
        XCTAssertEqual(didCallViewWillDisappear, true)
    }
    
    func testViewDidDisappear() {
        // Given
        var didCallViewDidDisappear: Bool?
        viewController.rx.viewDidDisappear
            .subscribe(onNext: {  animated in
                didCallViewDidDisappear = animated
            })
            .disposed(by: disposeBag)
        
        // When
        viewController.viewDidDisappear(false)
        
        // Then
        XCTAssertEqual(didCallViewDidDisappear, false)
    }
    
    func testViewDidDisappearAnimated() {
        // Given
        var didCallViewDidDisappear: Bool?
        viewController.rx.viewDidDisappear
            .subscribe(onNext: {  animated in
                didCallViewDidDisappear = animated
            })
            .disposed(by: disposeBag)
        
        // When
        viewController.viewDidDisappear(true)
        
        // Then
        XCTAssertEqual(didCallViewDidDisappear, true)
    }
    
    func testViewStates() {
        // Given
        var viewStates: [ViewControllerViewState] = []
        viewController.rx.viewState
            .subscribe(onNext: { viewState in
                viewStates.append(viewState)
            })
            .disposed(by: disposeBag)
        
        // When
        viewController.viewWillAppear(true)
        viewController.viewDidAppear(true)
        viewController.viewWillDisappear(true)
        viewController.viewDidDisappear(true)
        
        // Then
        XCTAssertEqual(viewStates, [.viewWillAppear, .viewDidAppear, .viewWillDisappear, .viewDidDisappear])
    }
}
