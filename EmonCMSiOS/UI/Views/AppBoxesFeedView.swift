//
//  AppFeedBoxView.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 14/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit

@IBDesignable final class AppBoxesFeedView: UIView {

  @IBInspectable var name: String = "FEED" { didSet { self.updateLabels() } }
  @IBInspectable var value: Double = 0 { didSet { self.updateLabels() } }
  @IBInspectable var unit: String = "kWh" { didSet { self.updateLabels() } }

  private let containerView = UIView(frame: .zero)
  private let nameLabel = UILabel(frame: .zero)
  private let valueLabel = UILabel(frame: .zero)
  private var internalConstraints: [NSLayoutConstraint] = []

  override class var requiresConstraintBasedLayout: Bool { return true }

  override init(frame: CGRect) {
    super.init(frame: frame)
    self.setupLabels()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.setupLabels()
  }

  private func setupLabels() {
    self.translatesAutoresizingMaskIntoConstraints = false

    self.containerView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.containerView)

    self.nameLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
    self.nameLabel.textAlignment = .center
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = false
    self.containerView.addSubview(self.nameLabel)

    self.valueLabel.font = UIFont.systemFont(ofSize: 16.0)
    self.valueLabel.textAlignment = .center
    self.valueLabel.translatesAutoresizingMaskIntoConstraints = false
    self.containerView.addSubview(self.valueLabel)

    self.updateLabels()
  }

  private func updateLabels() {
    self.nameLabel.text = self.name.uppercased()
    self.valueLabel.text = "\(self.value.prettyFormat(decimals: 1)) \(self.unit)"
  }

  override func updateConstraints() {
    super.updateConstraints()

    self.removeConstraints(self.internalConstraints)
    self.internalConstraints.removeAll()

    let views = ["containerView": self.containerView, "nameLabel": self.nameLabel, "valueLabel": self.valueLabel]

    self.internalConstraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=4)-[containerView]-(>=4)-|",
                                     options: [],
                                     metrics: nil,
                                     views: views)
    self.internalConstraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=4)-[containerView]-(>=4)-|",
                                     options: [],
                                     metrics: nil,
                                     views: views)
    self.internalConstraints +=
      [NSLayoutConstraint(item: self.containerView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0),
       NSLayoutConstraint(item: self.containerView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)]
    self.internalConstraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "V:|[nameLabel]-2-[valueLabel]|",
                                     options: [],
                                     metrics: nil,
                                     views: views)
    self.internalConstraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[nameLabel]-(0)-|",
                                     options: [],
                                     metrics: nil,
                                     views: views)
    self.internalConstraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[valueLabel]-(0)-|",
                                     options: [],
                                     metrics: nil,
                                     views: views)

    self.addConstraints(self.internalConstraints)
  }

}
