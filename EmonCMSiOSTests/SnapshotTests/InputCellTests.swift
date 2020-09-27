//
//  InputCellTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 27/09/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

@testable import EmonCMSiOS
import Nimble
import Quick
import SnapshotTesting
import UIKit

class InputCellTests: EmonCMSTestCase {
  private var cellSetup: (InputCell) -> Void = { _ in }

  override func setUp() {
    super.setUp()
    isRecording = false
  }

  override func spec() {
    var tableView: UITableView!
    var traits: UITraitCollection!

    beforeEach {
      tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 700), style: .plain)
      tableView.dataSource = self
      tableView.delegate = self
      tableView.register(UINib(nibName: "InputCell", bundle: nil), forCellReuseIdentifier: "InputCell")

      traits =
        UITraitCollection(traitsFrom: [
          UITraitCollection(displayScale: 2.0),
          UITraitCollection(userInterfaceStyle: .light)
        ])

      self.cellSetup = { _ in }
    }

    describe("inputCell") {
      it("Should display normally") {
        self.cellSetup = { cell in
          cell.titleLabel.text = "Input Name"
          cell.valueLabel.text = "123"
          cell.timeLabel.text = "10 seconds ago"
          cell.activityCircle.backgroundColor = EmonCMSColors.ActivityIndicator.Green
        }
        assertSnapshot(matching: tableView, as: .image(traits: traits))
      }
    }
  }
}

extension InputCellTests: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "InputCell", for: indexPath) as! InputCell
    self.cellSetup(cell)
    return cell
  }
}
