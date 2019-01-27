//
//  TodayViewController.swift
//  EmonCMSiOSToday
//
//  Created by Matt Galloway on 26/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit
import NotificationCenter

import Realm
import RealmSwift

class TodayViewController: UIViewController, NCWidgetProviding {

  @IBOutlet var tableView: UITableView!

  private var keychainController: KeychainController!
  private var realmController: RealmController!
  private var realm: Realm!
  private var accounts = [Account]()

  override func viewDidLoad() {
    super.viewDidLoad()

    self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded

    self.keychainController = KeychainController()
    let dataDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedConstants.SharedApplicationGroupIdentifier)!
    self.realmController = RealmController(dataDirectory: dataDirectory)
    self.realm = self.realmController.createRealm()
  }

  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
    let accounts = self.realm.objects(Account.self)
    self.accounts = Array(accounts)
    self.tableView.reloadData()
    completionHandler(NCUpdateResult.newData)
  }

  func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
    switch activeDisplayMode {
    case .compact:
      self.preferredContentSize = maxSize;
    default:
      self.preferredContentSize = CGSize(width: self.tableView.contentSize.width, height: self.tableView.contentSize.height + 20);
    }
  }

}

extension TodayViewController: UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.accounts.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    let account = self.accounts[indexPath.row]
    cell.textLabel?.text = account.name
    cell.detailTextLabel?.text = self.keychainController.apiKey(forAccountWithId: account.uuid)
    return cell
  }

}
