//
//  CombineTableViewDataSourceTests.swift
//  EmonCMSiOSTests
//
//  Created by Matt Galloway on 03/12/2020.
//  Copyright © 2020 Matt Galloway. All rights reserved.
//

import Combine
@testable import EmonCMSiOS
import EntwineTest
import Nimble
import Quick
import UIKit

class CombineTableViewDataSourceTests: QuickSpec {
  override func spec() {
    var scheduler: TestScheduler!

    beforeEach {
      scheduler = TestScheduler(initialClock: 0)
    }

    describe("SectionModel") {
      it("should return identity correctly") {
        typealias Model = SectionModel<String, String>
        let model = Model(model: "foo", items: ["bar", "baz"])
        expect(model.identity).to(equal("foo"))
      }

      it("should return description correctly") {
        typealias Model = SectionModel<String, String>
        let model = Model(model: "foo", items: ["bar", "baz"])
        expect(model.description).to(equal("foo > [\"bar\", \"baz\"]"))
      }

      it("should be equatable correctly") {
        typealias Model = SectionModel<String, String>

        let modelA = Model(model: "foo", items: ["bar", "baz"])
        let modelB = Model(model: "foo", items: ["bar", "baz"])
        let modelC = Model(model: "bar", items: ["bar", "baz"])
        let modelD = Model(model: "foo", items: ["foo", "bar"])

        expect(modelA).to(equal(modelB))
        expect(modelA).toNot(equal(modelC))
        expect(modelA).toNot(equal(modelD))
      }
    }

    describe("CombineTableViewDataSource") {
      it("should ask for the right cells") {
        typealias Model = SectionModel<String, String>

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 700), style: .plain)

        var cells: [IndexPath: UITableViewCell] = [:]
        let dataSource = CombineTableViewDataSource<Model> { (_, _, indexPath, item) -> UITableViewCell in
          let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
          cell.textLabel?.text = item
          cells[indexPath] = cell
          return cell
        } titleForHeaderInSection: { (_, _) -> String? in
          nil
        } titleForFooterInSection: { (_, _) -> String? in
          nil
        } canEditRowAtIndexPath: { (_, _) -> Bool in
          true
        } canMoveRowAtIndexPath: { (_, _) -> Bool in
          true
        } heightForRowAtIndexPath: { (_, _) -> CGFloat in
          44.0
        }

        let items = Just<[Model]>([Model(model: "section1", items: ["foo", "bar", "baz"])]).eraseToAnyPublisher()
        dataSource.assign(toTableView: tableView, items: items)
        tableView.layoutIfNeeded()

        expect(cells.count).to(equal(3))
        expect(cells[IndexPath(row: 0, section: 0)]?.textLabel?.text).to(equal("foo"))
        expect(cells[IndexPath(row: 1, section: 0)]?.textLabel?.text).to(equal("bar"))
        expect(cells[IndexPath(row: 2, section: 0)]?.textLabel?.text).to(equal("baz"))
      }

      it("should get and set models correctly") {
        typealias Model = SectionModel<String, String>

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 700), style: .plain)

        let dataSource = CombineTableViewDataSource<Model> { (_, _, _, _) -> UITableViewCell in
          UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let items = Just<[Model]>([Model(model: "section1", items: ["foo", "bar", "baz"])]).eraseToAnyPublisher()
        dataSource.assign(toTableView: tableView, items: items)

        expect(dataSource[0].items.count).to(equal(3))
        expect(dataSource[IndexPath(row: 0, section: 0)]).to(equal("foo"))
        expect(dataSource[IndexPath(row: 1, section: 0)]).to(equal("bar"))
        expect(dataSource[IndexPath(row: 2, section: 0)]).to(equal("baz"))

        dataSource[IndexPath(row: 0, section: 0)] = "new"
        expect(dataSource[IndexPath(row: 0, section: 0)]).to(equal("new"))
      }

      it("should fire selected cells publisher correctly") {
        typealias Model = SectionModel<String, String>

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 700), style: .plain)

        let dataSource = CombineTableViewDataSource<Model> { (_, _, _, _) -> UITableViewCell in
          UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let items = Just<[Model]>([Model(model: "section1", items: ["foo", "bar", "baz"])]).eraseToAnyPublisher()
        dataSource.assign(toTableView: tableView, items: items)
        tableView.layoutIfNeeded()

        scheduler.schedule(after: 250) {
          tableView.delegate?.tableView?(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        }

        scheduler.schedule(after: 260) {
          tableView.delegate?.tableView?(tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
        }

        scheduler.schedule(after: 270) {
          tableView.delegate?.tableView?(tableView, didSelectRowAt: IndexPath(row: 2, section: 0))
        }

        let sut = dataSource.itemSelected
        let results = scheduler.start { sut }

        let expected: TestSequence<IndexPath, Never> = [
          (200, .subscription),
          (250, .input(IndexPath(row: 0, section: 0))),
          (260, .input(IndexPath(row: 1, section: 0))),
          (270, .input(IndexPath(row: 2, section: 0)))
        ]

        expect(results.recordedOutput).to(equal(expected))
      }

      it("should fire selected models publisher correctly") {
        typealias Model = SectionModel<String, String>

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 700), style: .plain)

        let dataSource = CombineTableViewDataSource<Model> { (_, _, _, _) -> UITableViewCell in
          UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let items = Just<[Model]>([Model(model: "section1", items: ["foo", "bar", "baz"])]).eraseToAnyPublisher()
        dataSource.assign(toTableView: tableView, items: items)
        tableView.layoutIfNeeded()

        scheduler.schedule(after: 250) {
          tableView.delegate?.tableView?(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        }

        scheduler.schedule(after: 260) {
          tableView.delegate?.tableView?(tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
        }

        scheduler.schedule(after: 270) {
          tableView.delegate?.tableView?(tableView, didSelectRowAt: IndexPath(row: 2, section: 0))
        }

        let sut = dataSource.modelSelected
        let results = scheduler.start { sut }

        let expected: TestSequence<String, Never> = [
          (200, .subscription),
          (250, .input("foo")),
          (260, .input("bar")),
          (270, .input("baz"))
        ]

        expect(results.recordedOutput).to(equal(expected))
      }

      it("should fire deselected cells publisher correctly") {
        typealias Model = SectionModel<String, String>

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 700), style: .plain)

        let dataSource = CombineTableViewDataSource<Model> { (_, _, _, _) -> UITableViewCell in
          UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let items = Just<[Model]>([Model(model: "section1", items: ["foo", "bar", "baz"])]).eraseToAnyPublisher()
        dataSource.assign(toTableView: tableView, items: items)
        tableView.layoutIfNeeded()

        scheduler.schedule(after: 250) {
          tableView.delegate?.tableView?(tableView, didDeselectRowAt: IndexPath(row: 0, section: 0))
        }

        scheduler.schedule(after: 260) {
          tableView.delegate?.tableView?(tableView, didDeselectRowAt: IndexPath(row: 1, section: 0))
        }

        scheduler.schedule(after: 270) {
          tableView.delegate?.tableView?(tableView, didDeselectRowAt: IndexPath(row: 2, section: 0))
        }

        let sut = dataSource.itemDeselected
        let results = scheduler.start { sut }

        let expected: TestSequence<IndexPath, Never> = [
          (200, .subscription),
          (250, .input(IndexPath(row: 0, section: 0))),
          (260, .input(IndexPath(row: 1, section: 0))),
          (270, .input(IndexPath(row: 2, section: 0)))
        ]

        expect(results.recordedOutput).to(equal(expected))
      }

      it("should fire deselected models publisher correctly") {
        typealias Model = SectionModel<String, String>

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 700), style: .plain)

        let dataSource = CombineTableViewDataSource<Model> { (_, _, _, _) -> UITableViewCell in
          UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let items = Just<[Model]>([Model(model: "section1", items: ["foo", "bar", "baz"])]).eraseToAnyPublisher()
        dataSource.assign(toTableView: tableView, items: items)
        tableView.layoutIfNeeded()

        scheduler.schedule(after: 250) {
          tableView.delegate?.tableView?(tableView, didDeselectRowAt: IndexPath(row: 0, section: 0))
        }

        scheduler.schedule(after: 260) {
          tableView.delegate?.tableView?(tableView, didDeselectRowAt: IndexPath(row: 1, section: 0))
        }

        scheduler.schedule(after: 270) {
          tableView.delegate?.tableView?(tableView, didDeselectRowAt: IndexPath(row: 2, section: 0))
        }

        let sut = dataSource.modelDeselected
        let results = scheduler.start { sut }

        let expected: TestSequence<String, Never> = [
          (200, .subscription),
          (250, .input("foo")),
          (260, .input("bar")),
          (270, .input("baz"))
        ]

        expect(results.recordedOutput).to(equal(expected))
      }

      it("should fire accessory button tapped publisher correctly") {
        typealias Model = SectionModel<String, String>

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 700), style: .plain)

        let dataSource = CombineTableViewDataSource<Model> { (_, _, _, _) -> UITableViewCell in
          UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let items = Just<[Model]>([Model(model: "section1", items: ["foo", "bar", "baz"])]).eraseToAnyPublisher()
        dataSource.assign(toTableView: tableView, items: items)
        tableView.layoutIfNeeded()

        scheduler.schedule(after: 250) {
          tableView.delegate?.tableView?(tableView, accessoryButtonTappedForRowWith: IndexPath(row: 0, section: 0))
        }

        scheduler.schedule(after: 260) {
          tableView.delegate?.tableView?(tableView, accessoryButtonTappedForRowWith: IndexPath(row: 1, section: 0))
        }

        scheduler.schedule(after: 270) {
          tableView.delegate?.tableView?(tableView, accessoryButtonTappedForRowWith: IndexPath(row: 2, section: 0))
        }

        let sut = dataSource.itemAccessoryButtonTapped
        let results = scheduler.start { sut }

        let expected: TestSequence<IndexPath, Never> = [
          (200, .subscription),
          (250, .input(IndexPath(row: 0, section: 0))),
          (260, .input(IndexPath(row: 1, section: 0))),
          (270, .input(IndexPath(row: 2, section: 0)))
        ]

        expect(results.recordedOutput).to(equal(expected))
      }

      it("should fire item deleted publisher correctly") {
        typealias Model = SectionModel<String, String>

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 700), style: .plain)

        let dataSource = CombineTableViewDataSource<Model> { (_, _, _, _) -> UITableViewCell in
          UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let items = Just<[Model]>([Model(model: "section1", items: ["foo", "bar", "baz"])]).eraseToAnyPublisher()
        dataSource.assign(toTableView: tableView, items: items)
        tableView.layoutIfNeeded()

        scheduler.schedule(after: 250) {
          tableView.dataSource?.tableView?(tableView, commit: .delete, forRowAt: IndexPath(row: 0, section: 0))
        }

        scheduler.schedule(after: 260) {
          tableView.dataSource?.tableView?(tableView, commit: .delete, forRowAt: IndexPath(row: 1, section: 0))
        }

        scheduler.schedule(after: 270) {
          tableView.dataSource?.tableView?(tableView, commit: .delete, forRowAt: IndexPath(row: 2, section: 0))
        }

        let sut = dataSource.itemDeleted
        let results = scheduler.start { sut }

        let expected: TestSequence<IndexPath, Never> = [
          (200, .subscription),
          (250, .input(IndexPath(row: 0, section: 0))),
          (260, .input(IndexPath(row: 1, section: 0))),
          (270, .input(IndexPath(row: 2, section: 0)))
        ]

        expect(results.recordedOutput).to(equal(expected))
      }

      it("should fire model deleted publisher correctly") {
        typealias Model = SectionModel<String, String>

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 375, height: 700), style: .plain)

        let dataSource = CombineTableViewDataSource<Model> { (_, _, _, _) -> UITableViewCell in
          UITableViewCell(style: .default, reuseIdentifier: nil)
        }

        let items = Just<[Model]>([Model(model: "section1", items: ["foo", "bar", "baz"])]).eraseToAnyPublisher()
        dataSource.assign(toTableView: tableView, items: items)
        tableView.layoutIfNeeded()

        scheduler.schedule(after: 250) {
          tableView.dataSource?.tableView?(tableView, commit: .delete, forRowAt: IndexPath(row: 0, section: 0))
        }

        scheduler.schedule(after: 260) {
          tableView.dataSource?.tableView?(tableView, commit: .delete, forRowAt: IndexPath(row: 1, section: 0))
        }

        scheduler.schedule(after: 270) {
          tableView.dataSource?.tableView?(tableView, commit: .delete, forRowAt: IndexPath(row: 2, section: 0))
        }

        let sut = dataSource.modelDeleted
        let results = scheduler.start { sut }

        let expected: TestSequence<String, Never> = [
          (200, .subscription),
          (250, .input("foo")),
          (260, .input("bar")),
          (270, .input("baz"))
        ]

        expect(results.recordedOutput).to(equal(expected))
      }
    }
  }
}
