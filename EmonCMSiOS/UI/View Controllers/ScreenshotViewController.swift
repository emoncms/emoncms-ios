//
//  ScreenshotViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 13/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

class ScreenshotViewController: UIViewController {

  private var snapshotView: UIView?

  init(viewToScreenshot view: UIView) {
    super.init(nibName: nil, bundle: nil)

    let snapshotView = view.snapshotView(afterScreenUpdates: true)
    self.snapshotView = snapshotView
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    if let snapshotView = self.snapshotView {
      self.view.addSubview(snapshotView)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if let snapshotView = self.snapshotView {
      snapshotView.frame = self.view.bounds
    }
  }

}
