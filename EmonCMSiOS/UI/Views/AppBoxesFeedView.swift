//
//  AppFeedBoxView.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit

@IBDesignable final class AppBoxesFeedView: UIView {

  @IBInspectable var name: String = "FEED" { didSet { self.setNeedsLayout() } }
  @IBInspectable var value: Double = 0 { didSet { self.setNeedsLayout() } }
  @IBInspectable var unit: String = "kWh" { didSet { self.setNeedsLayout() } }

  private var nameLabel: UILabel!
  private var valueLabel: UILabel!

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setupLabels()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setupLabels()
  }

  private func setupLabels() {
    let nameLabel = UILabel(frame: .zero)
    nameLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
    nameLabel.textAlignment = .center
    self.addSubview(nameLabel)
    self.nameLabel = nameLabel

    let valueLabel = UILabel(frame: .zero)
    valueLabel.font = UIFont.systemFont(ofSize: 16.0)
    valueLabel.textAlignment = .center
    self.addSubview(valueLabel)
    self.valueLabel = valueLabel
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let bounds = self.bounds
    self.nameLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height / 2.0)
    self.valueLabel.frame = CGRect(x: 0, y: bounds.height / 2.0, width: bounds.width, height: bounds.height / 2.0)

    self.nameLabel.text = self.name.uppercased()
    self.valueLabel.text = "\(self.value.prettyFormat(decimals: 1)) \(self.unit)"
  }

}
