//
//  CombineTableViewDataSource.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 12/08/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

// INSPIRED BY https://github.com/RxSwiftCommunity/RxDataSources

import Combine
import UIKit

public protocol SectionModelType {
  associatedtype Item

  var items: [Item] { get }

  init(original: Self, items: [Item])
}

public struct SectionModel<Section, ItemType> {
  public var model: Section
  public var items: [Item]

  public init(model: Section, items: [Item]) {
    self.model = model
    self.items = items
  }
}

extension SectionModel: SectionModelType {
  public typealias Identity = Section
  public typealias Item = ItemType

  public var identity: Section {
    return self.model
  }
}

extension SectionModel:
  CustomStringConvertible {
    public var description: String {
      return "\(self.model) > \(self.items)"
    }
  }

extension SectionModel {
  public init(original: SectionModel<Section, Item>, items: [Item]) {
    self.model = original.model
    self.items = items
  }
}

extension SectionModel:
  Equatable where Section: Equatable, ItemType: Equatable {
  public static func == (lhs: SectionModel, rhs: SectionModel) -> Bool {
    return lhs.model == rhs.model
      && lhs.items == rhs.items
  }
}

extension Array where Element: SectionModelType {
  mutating func moveFromSourceIndexPath(_ sourceIndexPath: IndexPath, destinationIndexPath: IndexPath) {
    let sourceSection = self[sourceIndexPath.section]
    var sourceItems = sourceSection.items

    let sourceItem = sourceItems.remove(at: sourceIndexPath.item)

    let sourceSectionNew = Element(original: sourceSection, items: sourceItems)
    self[sourceIndexPath.section] = sourceSectionNew

    let destinationSection = self[destinationIndexPath.section]
    var destinationItems = destinationSection.items
    destinationItems.insert(sourceItem, at: destinationIndexPath.item)

    self[destinationIndexPath.section] = Element(original: destinationSection, items: destinationItems)
  }
}

final class CombineTableViewDataSource<Section: SectionModelType>:
  NSObject,
  UITableViewDataSource,
  UITableViewDelegate {
  public typealias Item = Section.Item

  public typealias ConfigureCell = (CombineTableViewDataSource<Section>, UITableView, IndexPath, Item)
    -> UITableViewCell
  public typealias TitleForHeaderInSection = (CombineTableViewDataSource<Section>, Int) -> String?
  public typealias TitleForFooterInSection = (CombineTableViewDataSource<Section>, Int) -> String?
  public typealias CanEditRowAtIndexPath = (CombineTableViewDataSource<Section>, IndexPath) -> Bool
  public typealias CanMoveRowAtIndexPath = (CombineTableViewDataSource<Section>, IndexPath) -> Bool
  public typealias HeightForRowAtIndexPath = (CombineTableViewDataSource<Section>, IndexPath) -> CGFloat

  let configureCell: ConfigureCell
  let titleForHeaderInSection: TitleForHeaderInSection
  let titleForFooterInSection: TitleForFooterInSection
  let canEditRowAtIndexPath: CanEditRowAtIndexPath
  let canMoveRowAtIndexPath: CanMoveRowAtIndexPath
  let heightForRowAtIndexPath: HeightForRowAtIndexPath

  private weak var tableView: UITableView?
  private var cancellables = Set<AnyCancellable>()

  init(
    configureCell: @escaping ConfigureCell,
    titleForHeaderInSection: @escaping TitleForHeaderInSection = { _, _ in nil },
    titleForFooterInSection: @escaping TitleForFooterInSection = { _, _ in nil },
    canEditRowAtIndexPath: @escaping CanEditRowAtIndexPath = { _, _ in false },
    canMoveRowAtIndexPath: @escaping CanMoveRowAtIndexPath = { _, _ in false },
    heightForRowAtIndexPath: @escaping HeightForRowAtIndexPath = { _, _ in UITableView.automaticDimension }) {
    self.configureCell = configureCell
    self.titleForHeaderInSection = titleForHeaderInSection
    self.titleForFooterInSection = titleForFooterInSection
    self.canEditRowAtIndexPath = canEditRowAtIndexPath
    self.canMoveRowAtIndexPath = canMoveRowAtIndexPath
    self.heightForRowAtIndexPath = heightForRowAtIndexPath
  }

  func assign(toTableView tableView: UITableView, items: AnyPublisher<[Section], Never>) {
    tableView.delegate = self
    tableView.dataSource = self
    tableView.layoutIfNeeded()
    self.tableView = tableView
    items
      .sink { [weak self] sections in
        self?.setSections(sections)
        self?.tableView?.reloadData()
      }
      .store(in: &self.cancellables)
  }

  var itemSelected: AnyPublisher<IndexPath, Never> { return self.itemSelectedSubject.eraseToAnyPublisher() }
  var modelSelected: AnyPublisher<Item, Never> {
    return self.itemSelectedSubject.map(self.model(at:)).eraseToAnyPublisher()
  }

  private let itemSelectedSubject = PassthroughSubject<IndexPath, Never>()

  var itemDeselected: AnyPublisher<IndexPath, Never> { return self.itemDeselectedSubject.eraseToAnyPublisher() }
  var modelDeselected: AnyPublisher<Item, Never> {
    return self.itemDeselectedSubject.map(self.model(at:)).eraseToAnyPublisher()
  }

  private let itemDeselectedSubject = PassthroughSubject<IndexPath, Never>()

  var itemAccessoryButtonTapped: AnyPublisher<IndexPath, Never> {
    return self.itemAccessoryButtonTappedSubject.eraseToAnyPublisher()
  }

  private let itemAccessoryButtonTappedSubject = PassthroughSubject<IndexPath, Never>()

  var itemDeleted: AnyPublisher<IndexPath, Never> { return self.itemDeletedSubject.eraseToAnyPublisher() }
  var modelDeleted: AnyPublisher<Item, Never> {
    return self.itemDeletedSubject.map(self.model(at:)).eraseToAnyPublisher()
  }

  private let itemDeletedSubject = PassthroughSubject<IndexPath, Never>()

  var itemMoved: AnyPublisher<(IndexPath, IndexPath), Never> { return self.itemMovedSubject.eraseToAnyPublisher() }
  private let itemMovedSubject = PassthroughSubject<(IndexPath, IndexPath), Never>()

  // MARK:

  typealias SectionModelSnapshot = SectionModel<Section, Item>

  private var _sectionModels: [SectionModelSnapshot] = []

  var sectionModels: [Section] {
    return self._sectionModels.map { Section(original: $0.model, items: $0.items) }
  }

  subscript(section: Int) -> Section {
    let sectionModel = self._sectionModels[section]
    return Section(original: sectionModel.model, items: sectionModel.items)
  }

  subscript(indexPath: IndexPath) -> Item {
    get {
      return self._sectionModels[indexPath.section].items[indexPath.item]
    }
    set(item) {
      var section = self._sectionModels[indexPath.section]
      section.items[indexPath.item] = item
      self._sectionModels[indexPath.section] = section
    }
  }

  func model(at indexPath: IndexPath) -> Item {
    return self[indexPath]
  }

  func setSections(_ sections: [Section]) {
    self._sectionModels = sections.map { SectionModelSnapshot(model: $0, items: $0.items) }
  }

  // MARK: UITableViewDataSource

  func numberOfSections(in tableView: UITableView) -> Int {
    return self._sectionModels.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard self._sectionModels.count > section else { return 0 }
    return self._sectionModels[section].items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    precondition(indexPath.item < self._sectionModels[indexPath.section].items.count)

    return self.configureCell(self, tableView, indexPath, self[indexPath])
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return self.titleForHeaderInSection(self, section)
  }

  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    return self.titleForFooterInSection(self, section)
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return self.canEditRowAtIndexPath(self, indexPath)
  }

  func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return self.canMoveRowAtIndexPath(self, indexPath)
  }

  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    self._sectionModels.moveFromSourceIndexPath(sourceIndexPath, destinationIndexPath: destinationIndexPath)
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return self.heightForRowAtIndexPath(self, indexPath)
  }

  // MARK: UITableViewDelegate

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.itemSelectedSubject.send(indexPath)
  }

  func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    self.itemDeselectedSubject.send(indexPath)
  }

  func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    self.itemAccessoryButtonTappedSubject.send(indexPath)
  }

  func tableView(
    _ tableView: UITableView,
    commit editingStyle: UITableViewCell.EditingStyle,
    forRowAt indexPath: IndexPath) {
    switch editingStyle {
    case .delete:
      self.itemDeletedSubject.send(indexPath)
    case .insert:
      break
    case .none:
      break
    @unknown default:
      break
    }
  }
}
