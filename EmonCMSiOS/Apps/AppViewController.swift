//
//  AppViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 16/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class AppViewController: UIViewController {

  var viewModel: AppViewModel!

  @IBOutlet private var mainView: UIView!
  @IBOutlet private var configureView: UIView!

  private var pageViewController: UIPageViewController!
  private var pages = [UIViewController]()

  private let disposeBag = DisposeBag()

  private enum Segues: String {
    case pageVC
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.navigationItem.largeTitleDisplayMode = .never
    self.view.accessibilityIdentifier = self.viewModel.accessibilityIdentifier

    let pageControlAppearance = UIPageControl.appearance(whenContainedInInstancesOf: [AppViewController.self])
    pageControlAppearance.pageIndicatorTintColor = .lightGray
    pageControlAppearance.currentPageIndicatorTintColor = .black

    self.setupBindings()
    self.setupNavigation()
  }

  private func setupBindings() {
    self.viewModel.title
      .drive(self.rx.title)
      .disposed(by: self.disposeBag)

    self.viewModel.isReady
      .map { !$0 }
      .drive(self.mainView.rx.isHidden)
      .disposed(by: self.disposeBag)

    self.viewModel.isReady
      .drive(self.configureView.rx.isHidden)
      .disposed(by: self.disposeBag)
  }

  private func setupNavigation() {
    let rightBarButtonItem = UIBarButtonItem(title: "Configure", style: .plain, target: nil, action: nil)
    rightBarButtonItem.rx.tap
      .flatMap { [weak self] _ -> Driver<AppUUIDAndCategory?> in
        guard let strongSelf = self else { return Driver.empty() }

        let configViewController = AppConfigViewController()
        configViewController.viewModel = strongSelf.viewModel.configViewModel()
        let navController = UINavigationController(rootViewController: configViewController)
        strongSelf.present(navController, animated: true, completion: nil)

        return configViewController.finished
      }
      .subscribe(onNext: { [weak self] _ in
        guard let strongSelf = self else { return }
        strongSelf.dismiss(animated: true, completion: nil)
      })
      .disposed(by: self.disposeBag)
    self.navigationItem.rightBarButtonItem = rightBarButtonItem
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)

    if segue.identifier == Segues.pageVC.rawValue {
      if let pageViewController = segue.destination as? UIPageViewController {
        let identifiers = self.viewModel.pageViewControllerStoryboardIdentifiers
        let viewModels = self.viewModel.pageViewModels
        let pages = zip(identifiers, viewModels).map { arg -> UIViewController in
          let (identifier, viewModel) = arg
          let page = self.storyboard?.instantiateViewController(withIdentifier: identifier) as! AppPageViewController
          page.viewModel = viewModel
          return page
        }
        self.pages = pages

        if let firstPage = pages.first {
          pageViewController.dataSource = self
          pageViewController.setViewControllers([firstPage], direction: .forward, animated: false, completion: nil)
          self.pageViewController = pageViewController
        }
      }
    }
  }

}

extension AppViewController: UIPageViewControllerDataSource {

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let index = self.pages.firstIndex(of: viewController), index > 0 else { return nil }
    return self.pages[index - 1]
  }

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let index = self.pages.firstIndex(of: viewController), index < (self.pages.count - 1) else { return nil }
    return self.pages[index + 1]
  }

  func presentationCount(for pageViewController: UIPageViewController) -> Int {
    return self.pages.count
  }

  func presentationIndex(for pageViewController: UIPageViewController) -> Int {
    guard
      let topViewController = pageViewController.viewControllers?.first,
      let index = self.pages.firstIndex(of: topViewController)
      else { return 0 }

    return index
  }

}
