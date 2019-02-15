//
//  AppTitleAndValueView.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 24/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

@IBDesignable final class AppTitleAndValueView: UIView {

  @IBInspectable var title: String? { get { return self.titleLabel.text } set { self.titleLabel.text = newValue } }
  @IBInspectable var titleColor: UIColor { get { return self.titleLabel.textColor } set { self.titleLabel.textColor = newValue } }
  @IBInspectable var value: String? { get { return self.valueLabel.text } set { self.valueLabel.text = newValue } }
  @IBInspectable var valueColor: UIColor { get { return self.valueLabel.textColor } set { self.valueLabel.textColor = newValue } }

  var alignment: NSTextAlignment {
    get { return self.titleLabel.textAlignment }
    set {
      self.titleLabel.textAlignment = newValue
      self.valueLabel.textAlignment = newValue
    }
  }

  private let titleLabel = UILabel(frame: .zero)
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

    self.titleLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .bold)
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.titleLabel)

    self.valueLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .bold)
    self.valueLabel.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.valueLabel)
  }

  override func updateConstraints() {
    super.updateConstraints()

    self.removeConstraints(self.internalConstraints)
    self.internalConstraints.removeAll()

    let views = ["titleLabel": self.titleLabel, "valueLabel": self.valueLabel]

    self.internalConstraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "V:|[titleLabel]-2-[valueLabel]|",
                                     options: [],
                                     metrics: nil,
                                     views: views)
    self.internalConstraints +=
      NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[titleLabel]-(0)-|",
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

extension Reactive where Base: AppTitleAndValueView {

  var title: Binder<String?> {
    return Binder(self.base) { view, text in
      view.title = text
    }
  }

  var titleColor: Binder<UIColor> {
    return Binder(self.base) { view, color in
      view.titleColor = color
    }
  }

  var value: Binder<String?> {
    return Binder(self.base) { view, text in
      view.value = text
    }
  }

  var valueColor: Binder<UIColor> {
    return Binder(self.base) { view, color in
      view.valueColor = color
    }
  }

}
