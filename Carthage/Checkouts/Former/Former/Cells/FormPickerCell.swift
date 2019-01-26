//
//  FormPickerCell.swift
//  Former-Demo
//
//  Created by Ryo Aoyama on 8/2/15.
//  Copyright © 2015 Ryo Aoyama. All rights reserved.
//

import UIKit

open class FormPickerCell: FormCell, PickerFormableRow {
    
    // MARK: Public
    
    public private(set) weak var pickerView: UIPickerView!
    
    public func formPickerView() -> UIPickerView {
        return pickerView
    }
    
    open override func setup() {
        super.setup()
        
        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.insertSubview(pickerView, at: 0)
        self.pickerView = pickerView
        
        let constraints = [
          NSLayoutConstraint.constraints(
            withVisualFormat: "V:|-15-[picker]-15-|",
                options: [],
                metrics: nil,
                views: ["picker": pickerView]
            ),
          NSLayoutConstraint.constraints(
            withVisualFormat: "H:|-0-[picker]-0-|",
                options: [],
                metrics: nil,
                views: ["picker": pickerView]
            )
            ].flatMap { $0 }
        contentView.addConstraints(constraints)
    }
}
