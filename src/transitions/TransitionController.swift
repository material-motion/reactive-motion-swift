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

extension UIViewController {
  private struct AssociatedKeys {
    static var transitionController = "MDMTransitionController"
  }

  /**
   A transition controller may be used to implement custom Material Motion transitions.

   The transition controller is lazily created upon access. If the view controller's
   transitioningDelegate is nil when the controller is created, then the controller will also be set
   to the transitioningDelegate property.
   */
  public var transitionController: TransitionController {
    get {
      if let controller = objc_getAssociatedObject(self, &AssociatedKeys.transitionController) as? TransitionController {
        return controller
      }

      let controller = TransitionController(viewController: self)
      objc_setAssociatedObject(self, &AssociatedKeys.transitionController, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

      if transitioningDelegate == nil {
        transitioningDelegate = controller.transitioningDelegate
      }

      return controller
    }
  }
}

/**
 A TransitionController is the bridging object between UIKit's view controller transitioning
 APIs and Material Motion transitions.

 This class is not meant to be instantiated directly.
 */
public final class TransitionController {

  /**
   An instance of the directorClass will be created to describe the motion for this transition
   controller's transitions.

   If no directorClass is provided then a default UIKit transition will be used.

   Must be a subclass of MDMTransition.
   */
  public var transitionType: Transition.Type? {
    set { _transitioningDelegate.transitionType = newValue }
    get { return _transitioningDelegate.transitionType }
  }

  /**
   Start a dismiss transition when the given gesture recognizer enters its began or recognized
   state.

   The provided gesture recognizer will be made available to the transition instance via the
   TransitionContext's `gestureRecognizers` property.
   */
  public func dismissWhenGestureRecognizerBegins(_ gestureRecognizer: UIGestureRecognizer) {
    _transitioningDelegate.dismisser.dismissWhenGestureRecognizerBegins(gestureRecognizer)
  }

  /**
   Will not allow the provided gesture recognizer to recognize simultaneously with other gesture
   recognizers.

   This method assumes that the provided gesture recognizer's delegate has been assigned to the
   transition controller's gesture delegate.
   */
  public func disableSimultaneousRecognition(of gestureRecognizer: UIGestureRecognizer) {
    _transitioningDelegate.dismisser.disableSimultaneousRecognition(of: gestureRecognizer)
  }

  /**
   Returns a gesture recognizer delegate that will allow the gesture recognizer to begin only if the
   provided scroll view is scrolled to the top of its content.

   The returned delegate implements gestureRecognizerShouldBegin.
   */
  public func topEdgeDismisserDelegate(for scrollView: UIScrollView) -> UIGestureRecognizerDelegate {
    return _transitioningDelegate.dismisser.topEdgeDismisserDelegate(for: scrollView)
  }

  /**
   The set of gesture recognizers that will be provided to the transition via the TransitionContext
   instance.
   */
  public var gestureRecognizers: Set<UIGestureRecognizer> {
    set { _transitioningDelegate.gestureDelegate.gestureRecognizers = newValue }
    get { return _transitioningDelegate.gestureDelegate.gestureRecognizers }
  }

  public var foreAlignmentEdge: CGRectEdge? {
    set { _transitioningDelegate.foreAlignmentEdge = newValue }
    get { return _transitioningDelegate.foreAlignmentEdge }
  }

  /**
   The transitioning delegate managed by this controller.

   This object can be assigned to the view controller's transitioningDelegate. This is done
   automatically when a view controller's `transitionController` is first accessed.
   */
  public var transitioningDelegate: UIViewControllerTransitioningDelegate {
    return _transitioningDelegate
  }

  /**
   The gesture recognizer delegate managed by this controller.
   */
  public var gestureDelegate: UIGestureRecognizerDelegate {
    return _transitioningDelegate.gestureDelegate
  }

  init(viewController: UIViewController) {
    _transitioningDelegate = TransitioningDelegate(viewController: viewController)
  }

  /**
   Deprecated. Please use methods directly on the transitionController instead.
   */
  @available(*, deprecated, message: "Please use methods directly on the transitionController instead.")
  public var dismisser: ViewControllerDismisser {
    return _transitioningDelegate.dismisser
  }

  fileprivate let _transitioningDelegate: TransitioningDelegate
}

private final class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
  init(viewController: UIViewController) {
    self.associatedViewController = viewController

    self.dismisser = ViewControllerDismisser(gestureDelegate: self.gestureDelegate)

    super.init()

    self.dismisser.delegate = self
  }

  var foreAlignmentEdge: CGRectEdge?
  var ctx: TransitionContext?
  var transitionType: Transition.Type?

  let dismisser: ViewControllerDismisser
  let gestureDelegate = GestureDelegate()

  weak var associatedViewController: UIViewController?

  func prepareForTransition(withSource: UIViewController,
                            back: UIViewController,
                            fore: UIViewController,
                            direction: TransitionDirection) {
    // It's possible for a backward transition to be initiated while a forward transition is active.
    // We prefer the most recent transition in this case by blowing away the existing transition.
    if direction == .backward {
      ctx = nil
    }
    assert(ctx == nil, "A transition is already active.")

    if let transitionType = transitionType {
      if direction == .forward, let selfDismissingDirector = transitionType as? SelfDismissingTransition.Type {
        selfDismissingDirector.willPresent(fore: fore, dismisser: dismisser)
      }

      ctx = TransitionContext(transitionType: transitionType,
                              direction: direction,
                              back: back,
                              fore: fore,
                              gestureRecognizers: gestureDelegate.gestureRecognizers,
                              foreAlignmentEdge: foreAlignmentEdge)
      ctx?.delegate = self
    }
  }

  public func animationController(forPresented presented: UIViewController,
                                  presenting: UIViewController,
                                  source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    prepareForTransition(withSource: source,
                         back: presenting,
                         fore: presented,
                         direction: .forward)
    return ctx
  }

  public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    // The source is sadly lost by the time we get to dismissing the view controller, so we do our
    // best to infer what the source might have been.
    //
    // If the presenting view controller is a nav controller it's pretty likely that the view
    // controller was presented from its last view controller. Making this assumption is generally
    // harmless and only affects the view retriever search (by starting one view controller lower than
    // we otherwise would by using the navigation controller as the source).
    let source: UIViewController
    if let navController = dismissed.presentingViewController as? UINavigationController {
      source = navController.viewControllers.last!
    } else {
      source = dismissed.presentingViewController!
    }
    prepareForTransition(withSource: source,
                         back: dismissed.presentingViewController!,
                         fore: dismissed,
                         direction: .backward)
    return ctx
  }

  public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    if animator === ctx && isInteractive() {
      return ctx
    }
    return nil
  }

  public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    if animator === ctx && isInteractive() {
      return ctx
    }
    return nil
  }

  func isInteractive() -> Bool {
    return dismisser.gestureRecognizers.count > 0
  }
}

extension TransitioningDelegate: ViewControllerDismisserDelegate {
  func dismiss() {
    guard let associatedViewController = associatedViewController else {
      return
    }

    if associatedViewController.presentingViewController == nil {
      return
    }

    if associatedViewController.isBeingDismissed || associatedViewController.isBeingPresented {
      return
    }

    associatedViewController.dismiss(animated: true)
  }
}

extension TransitioningDelegate: TransitionDelegate {
  func transitionDidComplete(withContext ctx: TransitionContext) {
    if ctx === self.ctx {
      self.ctx = nil
    }
  }
}
