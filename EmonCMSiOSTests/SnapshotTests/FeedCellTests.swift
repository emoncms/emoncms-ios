//
//  FeedCellTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 27/09/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

// @testable import EmonCMSiOS
// import Nimble
// import Quick
// import Realm
// import RealmSwift
// import SnapshotTesting
// import UIKit
//
// class FeedCellTests: EmonCMSTestCase {
//  private var cellSetup: (FeedCell) -> Void = { _ in }
//
//  override func setUp() {
//    super.setUp()
//    isRecording = false
//  }
//
//  override func spec() {
//    var tableView: UITableView!
//    var traits: UITraitCollection!
//
//    beforeEach {
//      tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 700), style: .plain)
//      tableView.dataSource = self
//      tableView.delegate = self
//      tableView.register(UINib(nibName: "FeedCell", bundle: nil), forCellReuseIdentifier: "FeedCell")
//
//      traits =
//        UITraitCollection(traitsFrom: [
//          UITraitCollection(displayScale: 2.0),
//          UITraitCollection(userInterfaceStyle: .light)
//        ])
//
//      self.cellSetup = { _ in }
//    }
//
//    describe("feedCell") {
//      it("Should display normally") {
//        self.cellSetup = { cell in
//          cell.titleLabel.text = "Feed Name"
//          cell.valueLabel.text = "123"
//          cell.timeLabel.text = "10 seconds ago"
//          cell.activityCircle.backgroundColor = EmonCMSColors.ActivityIndicator.Green
//          cell.chartViewModel.send(nil)
//        }
//        tableView.layoutIfNeeded()
//        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
//        assertSnapshot(matching: tableView, as: .image(traits: traits))
//      }
//
//      it("Should display expanded") {
//        self.cellSetup = { cell in
//          cell.titleLabel.text = "Feed Name"
//          cell.valueLabel.text = "123"
//          cell.timeLabel.text = "10 seconds ago"
//          cell.activityCircle.backgroundColor = EmonCMSColors.ActivityIndicator.Green
//          cell.chartViewModel.send(self.makeFeedChartViewModel())
//        }
//        tableView.layoutIfNeeded()
//        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
//        assertSnapshot(matching: tableView, as: .image(traits: traits))
//      }
//    }
//  }
//
//  private func makeFeedChartViewModel() -> FeedChartViewModel {
//    let realmController = RealmController(dataDirectory: self.dataDirectory)
//    let credentials = AccountCredentials(url: "https://test", apiKey: "ilikecats")
//    let accountController = AccountController(uuid: "testaccount-\(type(of: self))", credentials: credentials)
//    let realm = realmController.createAccountRealm(forAccountId: accountController.uuid)
//    try! realm.write {
//      realm.deleteAll()
//    }
//
//    let requestProvider = MockHTTPRequestProvider()
//    let api = EmonCMSAPI(requestProvider: requestProvider)
//    return FeedChartViewModel(account: accountController, api: api, feedId: "1")
//  }
// }
//
// extension FeedCellTests: UITableViewDataSource, UITableViewDelegate {
//  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    return 1
//  }
//
//  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//    let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath) as! FeedCell
//    self.cellSetup(cell)
//    return cell
//  }
// }
