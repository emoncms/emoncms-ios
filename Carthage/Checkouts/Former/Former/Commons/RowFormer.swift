//
//  RowFormer.swift
//  Former-Demo
//
//  Created by Ryo Aoyama on 7/23/15.
//  Copyright © 2015 Ryo Aoyama. All rights reserved.
//

import UIKit

public protocol FormableRow: class {
    
    func updateWithRowFormer(_ rowFormer: RowFormer)
}

open class RowFormer {
    
    // MARK: Public
    
    public internal(set) final weak var former: Former?
    public final let cellType: UITableViewCell.Type
    public final var rowHeight: CGFloat = 44
    public final var isEditing = false
    public final var enabled = true { didSet { update() } }
    open var canBecomeEditing: Bool {
        return false
    }
    
    internal init<T: UITableViewCell>(
        cellType: T.Type,
        instantiateType: Former.InstantiateType,
        cellSetup: ((T) -> Void)? = nil) {
            self.cellType = cellType
            self.instantiateType = instantiateType
            self.cellSetup = { cellSetup?(($0 as! T)) }
            initialized()
    }
    
    @discardableResult
    public final func cellSetup(_ handler: @escaping ((UITableViewCell) -> Void)) -> Self {
        cellSetup = handler
        return self
    }
    
    @discardableResult
    public final func dynamicRowHeight(_ handler: @escaping ((UITableView, IndexPath) -> CGFloat)) -> Self {
        dynamicRowHeight = handler
        return self
    }
    
    open func initialized() {}
    
    open func update() {
        cellInstance.isUserInteractionEnabled = enabled
        onUpdate?(self)
        
        if let formableRow = cellInstance as? FormableRow {
            formableRow.updateWithRowFormer(self)
        }
        
        if let inlineRow = self as? InlineForm {
            let inlineRowFormer = inlineRow.inlineRowFormer
            inlineRowFormer.update()
            
            if let inlineFormableRow = inlineRowFormer.cellInstance as? FormableRow {
                inlineFormableRow.updateWithRowFormer(inlineRowFormer)
            }
        }
    }
    
    open func cellSelected(indexPath: IndexPath) {
        if enabled {
            onSelected?(self)
        }
    }

    // MARK: Internal

    internal final var cellSetup: ((UITableViewCell) -> Void)?
    internal final var onSelected: ((RowFormer) -> Void)?
    internal final var onUpdate: ((RowFormer) -> Void)?
    internal final var dynamicRowHeight: ((UITableView, IndexPath) -> CGFloat)?
    
    internal final var cellInstance: UITableViewCell {
        if _cellInstance == nil {
            var cell: UITableViewCell?
            switch instantiateType {
            case .Class:
                cell = cellType.init(style: .default, reuseIdentifier: nil)
            case .Nib(nibName: let nibName):
                cell = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)!.first as? UITableViewCell
                assert(cell != nil, "[Former] Failed to load cell from nib (\(nibName)).")
            case .NibBundle(nibName: let nibName, bundle: let bundle):
                cell = bundle.loadNibNamed(nibName, owner: nil, options: nil)!.first as? UITableViewCell
                assert(cell != nil, "[Former] Failed to load cell from nib (nibName: \(nibName), bundle: \(bundle)).")
            }
            _cellInstance = cell
            cellInstanceInitialized(cell!)
            cellSetup?(cell!)
        }
        return _cellInstance!
    }
    
    internal func cellInstanceInitialized(_ cell: UITableViewCell) {}
    
    // MARK: Private
    
    private final var _cellInstance: UITableViewCell?
    private final let instantiateType: Former.InstantiateType
}
