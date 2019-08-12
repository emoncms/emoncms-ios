//
//  AppViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 16/01/2019.
//  Copyright © 2019 Matt Galloway. All rights reserved.
//

import UIKit
import Combine

class AppViewController: UIViewController {

  var viewModel: AppViewModel!

  @IBOutlet private var mainView: UIView!
  @IBOutlet private var configureView: UIView!

  private var pageViewController: UIPageViewController!
  private var pages = [UIViewController]()

  private var cancellables = Set<AnyCancellable>()

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
      .map { $0 as String? }
      .assign(to: \.title, on: self)
      .store(in: &self.cancellables)

    self.viewModel.isReady
      .map { !$0 }
      .assign(to: \.isHidden, on: self.mainView)
      .store(in: &self.cancellables)

    self.viewModel.isReady
      .assign(to: \.isHidden, on: self.configureView)
      .store(in: &self.cancellables)
  }

  private func setupNavigation() {
    let rightBarButtonItem = UIBarButtonItem(title: "Configure", style: .plain, target: nil, action: nil)
    rightBarButtonItem.publisher()
      .flatMap { [weak self] _ -> AnyPublisher<AppUUIDAndCategory?, Never> in
        guard let self = self else { return Empty<AppUUIDAndCategory?, Never>().eraseToAnyPublisher() }

        let configViewController = AppConfigViewController()
        configViewController.viewModel = self.viewModel.configViewModel()
        let navController = UINavigationController(rootViewController: configViewController)
        self.present(navController, animated: true, completion: nil)

        return configViewController.finished
      }
      .sink { [weak self] _ in
        guard let self = self else { return }
        self.dismiss(animated: true, completion: nil)
      }
      .store(in: &self.cancellables)
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
