//
//  ChartCell.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 19/09/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import Foundation

import Former
import Charts

final class ChartCell<ChartViewType: ChartViewBase>: UITableViewCell {

  let chartView: ChartViewType

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    self.chartView = ChartViewType()
    chartView.translatesAutoresizingMaskIntoConstraints = false

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
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("Must be initialised programatically")
  }

}
