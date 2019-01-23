//
//  ValueCell.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 26/11/2016.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

final class ValueCell: UITableViewCell {

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var valueLabel: UILabel!
  @IBOutlet var timeLabel: UILabel!
  @IBOutlet var activityCircle: UIView!

  override func layoutSubviews() {
    super.layoutSubviews()
    self.activityCircle.layer.cornerRadius = self.activityCircle.bounds.width / 2
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    let colour = self.activityCircle.backgroundColor
    super.setSelected(selected, animated: animated)
    self.activityCircle.backgroundColor = colour
  }

}
