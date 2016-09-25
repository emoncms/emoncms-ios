//
//  InterfaceController.swift
//  EmonCMSWatch Extension
//
//  Created by Matt Galloway on 23/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import WatchKit
import Foundation

import RxSwift
import RxCocoa

class FeedsInterfaceController: WKInterfaceController {

  var viewModel: FeedListViewModel!

  @IBOutlet var feedsTable: WKInterfaceTable!

  private var disposeBag = DisposeBag()

  override func awake(withContext context: Any?) {
    super.awake(withContext: context)

    let viewModel = context as! FeedListViewModel
    self.viewModel = viewModel

    self.updateBindings()
  }

  override func willActivate() {
    self.viewModel.active.value = true
  }

  override func didDeactivate() {
    self.viewModel.active.value = false
  }

  @IBAction func refresh() {
    self.viewModel.refresh.onNext(())
  }

  private func updateBindings() {
    let disposeBag = DisposeBag()

    viewModel.feeds
      .drive(onNext: { [weak self] feeds in
        guard let strongSelf = self else { return }
        strongSelf.feedsTable.setNumberOfRows(feeds.count, withRowType: "FeedRow")
        for (i, listItem) in feeds.enumerated() {
          let controller = strongSelf.feedsTable.rowController(at: i) as! FeedRowController
          controller.listItem = listItem
        }
      })
      .addDisposableTo(disposeBag)

    self.disposeBag = disposeBag
  }

}
