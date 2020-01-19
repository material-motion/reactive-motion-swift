/*
 Copyright 2016-present The Material Motion Authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import UIKit

public protocol TransitionContextViewRetriever {
  func contextViewForTransition(foreViewController: UIViewController) -> UIView?
}

public func transitionContextViewRetriever(for viewController: UIViewController) -> TransitionContextViewRetriever? {

  // Get the view retriever by walking up the source view controller hierarchy until we find one
  // that conforms to TransitionContextViewRetriever.
  var iterator: UIViewController? = viewController
  while iterator != nil {
    if let retriever = iterator as? TransitionContextViewRetriever {
      return retriever
    }
    iterator = viewController.parent
  }

  // Haven't found the view retriever yet, let's search the children.
    var queue = viewController.children

  while let childViewController = queue.first {
    if let retriever = childViewController as? TransitionContextViewRetriever {
      return retriever
    }
    queue.removeFirst()

    let childViewControllers: [UIViewController]
    switch childViewController {
    case let navigationController as UINavigationController:
      // Prefer the top-most view controller.
      if let topViewController = navigationController.topViewController {
        childViewControllers = [topViewController]
      } else {
        fallthrough
      }
    default:
        childViewControllers = childViewController.children
    }

    queue.append(contentsOf: childViewControllers)
  }

  return nil
}
