//
//  ChartCell.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 19/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import Former
import Charts

final class ChartCell<ChartViewType: ChartViewBase>: UITableViewCell {

  let chartView: ChartViewType
  let spinner: UIActivityIndicatorView

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    self.chartView = ChartViewType()
    chartView.translatesAutoresizingMaskIntoConstraints = false

    self.spinner = UIActivityIndicatorView(style: .medium)
    spinner.translatesAutoresizingMaskIntoConstraints = false
    spinner.hidesWhenStopped = true

    super.init(style: style, reuseIdentifier: reuseIdentifier)

    contentView.addSubview(chartView)
    contentView.addConstraint(
      NSLayoutConstraint(
        item: chartView,
        attribute: .top,
        relatedBy: .equal,
        toItem: contentView,
        attribute: .top,
        multiplier: 1,
        constant: 0))
    contentView.addConstraint(
      NSLayoutConstraint(
        item: chartView,
        attribute: .bottom,
        relatedBy: .equal,
        toItem: contentView,
        attribute: .bottom,
        multiplier: 1,
        constant: 0))
    contentView.addConstraint(
      NSLayoutConstraint(
        item: chartView,
        attribute: .left,
        relatedBy: .equal,
        toItem: contentView,
        attribute: .left,
        multiplier: 1,
        constant: 0))
    contentView.addConstraint(
      NSLayoutConstraint(
        item: chartView,
        attribute: .right,
        relatedBy: .equal,
        toItem: contentView,
        attribute: .right,
        multiplier: 1,
        constant: 0))

    contentView.addSubview(spinner)
    contentView.addConstraint(
      NSLayoutConstraint(
        item: spinner,
        attribute: .centerX,
        relatedBy: .equal,
        toItem: contentView,
        attribute: .centerX,
        multiplier: 1,
        constant: 0))
    contentView.addConstraint(
      NSLayoutConstraint(
        item: spinner,
        attribute: .centerY,
        relatedBy: .equal,
        toItem: contentView,
        attribute: .centerY,
        multiplier: 1,
        constant: 0))
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("Must be initialised programatically")
  }

}
