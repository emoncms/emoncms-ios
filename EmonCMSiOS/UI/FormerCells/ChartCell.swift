//
//  ChartCell.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 19/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import Charts
import Former

final class ChartCell<ChartViewType: ChartViewBase>: UITableViewCell {
  let chartView: ChartViewType
  let spinner: UIActivityIndicatorView

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    self.chartView = ChartViewType()
    self.chartView.translatesAutoresizingMaskIntoConstraints = false

    self.spinner = UIActivityIndicatorView(style: .medium)
    self.spinner.translatesAutoresizingMaskIntoConstraints = false
    self.spinner.hidesWhenStopped = true

    super.init(style: style, reuseIdentifier: reuseIdentifier)

    contentView.addSubview(self.chartView)
    contentView.addConstraint(
      NSLayoutConstraint(
        item: self.chartView,
        attribute: .top,
        relatedBy: .equal,
        toItem: contentView,
        attribute: .top,
        multiplier: 1,
        constant: 0))
    contentView.addConstraint(
      NSLayoutConstraint(
        item: self.chartView,
        attribute: .bottom,
        relatedBy: .equal,
        toItem: contentView,
        attribute: .bottom,
        multiplier: 1,
        constant: 0))
    contentView.addConstraint(
      NSLayoutConstraint(
        item: self.chartView,
        attribute: .left,
        relatedBy: .equal,
        toItem: contentView,
        attribute: .left,
        multiplier: 1,
        constant: 0))
    contentView.addConstraint(
      NSLayoutConstraint(
        item: self.chartView,
        attribute: .right,
        relatedBy: .equal,
        toItem: contentView,
        attribute: .right,
        multiplier: 1,
        constant: 0))

    contentView.addSubview(self.spinner)
    contentView.addConstraint(
      NSLayoutConstraint(
        item: self.spinner,
        attribute: .centerX,
        relatedBy: .equal,
        toItem: contentView,
        attribute: .centerX,
        multiplier: 1,
        constant: 0))
    contentView.addConstraint(
      NSLayoutConstraint(
        item: self.spinner,
        attribute: .centerY,
        relatedBy: .equal,
        toItem: contentView,
        attribute: .centerY,
        multiplier: 1,
        constant: 0))
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("Must be initialised programatically")
  }
}
