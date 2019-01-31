//
//  MySolarDivertAppViewController.swift
//  EmonCMSiOS
//
//  Created by Matt Galloway on 15/01/2019.
//  Copyright © 2016 Matt Galloway. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import Charts

final class MySolarDivertAppViewController: AppViewController {

  var typedViewModel: MySolarDivertAppViewModel {
    return self.viewModel as! MySolarDivertAppViewModel
  }

  private var pageViewController: UIPageViewController!

  private let disposeBag = DisposeBag()

  private var pages = [UIViewController]()

  private enum Segues: String {
    case pageVC
  }

  private enum ChildVCIdentifiers: String {
    case mySolarDivertPage1
    case mySolarDivertPage2
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let pageControlAppearance = UIPageControl.appearance(whenContainedInInstancesOf: [MySolarDivertAppViewController.self])
    pageControlAppearance.pageIndicatorTintColor = .lightGray
    pageControlAppearance.currentPageIndicatorTintColor = .black

    self.view.accessibilityIdentifier = AccessibilityIdentifiers.Apps.MySolarDivert
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == Segues.pageVC.rawValue {
      if let pageViewController = segue.destination as? UIPageViewController {
        let page1 = self.storyboard?.instantiateViewController(withIdentifier: ChildVCIdentifiers.mySolarDivertPage1.rawValue) as! MySolarDivertAppPage1ViewController
        page1.viewModel = self.typedViewModel.page1ViewModel
        let page2 = self.storyboard?.instantiateViewController(withIdentifier: ChildVCIdentifiers.mySolarDivertPage2.rawValue) as! MySolarDivertAppPage2ViewController
        page2.viewModel = self.typedViewModel.page2ViewModel
        self.pages = [page1, page2]
        pageViewController.dataSource = self
        pageViewController.setViewControllers([page1], direction: .forward, animated: false, completion: nil)
        self.pageViewController = pageViewController
      }
    }
  }

}

extension MySolarDivertAppViewController: UIPageViewControllerDataSource {

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
