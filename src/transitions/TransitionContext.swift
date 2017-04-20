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
import IndefiniteObservable

/**
 The possible directions of a transition.
 */
public enum TransitionDirection {
  /**
   The fore view controller is being presented.
   */
  case forward

  /**
   The fore view controller is being dismissed.
   */
  case backward
}

/** A Transition represents the essential state for a UIViewController transition. */
public final class TransitionContext: NSObject {

  /** The default duration for a view controller transition. */
  public static let defaultDuration: TimeInterval = 0.35

  /** The direction this transition is moving in. */
  public let direction: ReactiveProperty<TransitionDirection>

  /** The transition window for this transition. */
  public let window: TransitionTimeWindow

  public let replicator = ViewReplicator()

  /** The context view for this transition. */
  public func contextView() -> UIView? {
    if contextViewRetriever == nil {
      // transitionContextViewRetriever can be a relatively complex lookup if it can't
      // immediately find the context view retriever, thus the lazy lookup here.
      contextViewRetriever = transitionContextViewRetriever(for: back)
    }
    if hasFetchedContextView {
      return _contextView
    }
    hasFetchedContextView = true
    _contextView = contextViewRetriever!.contextViewForTransition(foreViewController: fore)
    return _contextView
  }
  private var contextViewRetriever: TransitionContextViewRetriever?
  private var hasFetchedContextView = false
  private var _contextView: UIView?

  /** The container view for the transition as reported by UIKit's transition context. */
  public func containerView() -> UIView {
    return context.containerView
  }

  /**
   The back view controller for this transition.

   This is the destination when the transition's direction is backward.
   */
  public let back: UIViewController

  /**
   The fore view controller for this transition.

   This is the destination when the transition's direction is forward.
   */
  public let fore: UIViewController

  public let foreAlignmentEdge: CGRectEdge?

  /** The set of gesture recognizers associated with this transition. */
  public let gestureRecognizers: Set<UIGestureRecognizer>

  /** The runtime to which motion should be registered. */
  fileprivate var runtime: MotionRuntime!

  weak var delegate: TransitionDelegate?

  init(transitionType: Transition.Type,
       direction: TransitionDirection,
       back: UIViewController,
       fore: UIViewController,
       gestureRecognizers: Set<UIGestureRecognizer>,
       foreAlignmentEdge: CGRectEdge?) {
    self.direction = createProperty("Transition.direction", withInitialValue: direction)
    self.initialDirection = direction
    self.back = back
    self.fore = fore
    self.gestureRecognizers = gestureRecognizers
    self.foreAlignmentEdge = foreAlignmentEdge
    self.window = TransitionTimeWindow(duration: TransitionContext.defaultDuration)

    // TODO: Create a Timeline.

    self.transition = transitionType.init()

    super.init()
  }

  fileprivate let initialDirection: TransitionDirection
  fileprivate var transition: Transition!
  fileprivate var context: UIViewControllerContextTransitioning!
  fileprivate var didRegisterTerminator = false
}

extension TransitionContext: UIViewControllerAnimatedTransitioning {
  public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return window.duration
  }

  public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    context = transitionContext

    initiateTransition()
  }

  public func animationEnded(_ transitionCompleted: Bool) {
  }
}

extension TransitionContext: UIViewControllerInteractiveTransitioning {
  public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
    context = transitionContext

    initiateTransition()
  }
}

private func preferredFrame(for viewController: UIViewController,
                            inBounds bounds: CGRect,
                            alignmentEdge: CGRectEdge?) -> CGRect? {
  guard viewController.preferredContentSize != .zero() else {
    return nil
  }

  let size = viewController.preferredContentSize
  let origin: CGPoint
  switch alignmentEdge {
  case nil: // Centered
    origin = .init(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2)
  case .minXEdge?:
    origin = .init(x: bounds.minX, y: bounds.midY - size.height / 2)
  case .minYEdge?:
    origin = .init(x: bounds.midX - size.width / 2, y: bounds.minY)
  case .maxXEdge?:
    origin = .init(x: bounds.maxX - size.width, y: bounds.midY - size.height / 2)
  case .maxYEdge?:
    origin = .init(x: bounds.midX - size.width / 2, y: bounds.maxY - size.height)
  }
  return CGRect(origin: origin, size: size)
}

extension TransitionContext {
  fileprivate func initiateTransition() {
    if let from = context.viewController(forKey: .from) {
      let finalFrame = context.finalFrame(for: from)
      if !finalFrame.isEmpty {
        from.view.frame = finalFrame
      }
    }

    if let to = context.viewController(forKey: .to) {
      let finalFrame: CGRect

      if let preferredFrame = preferredFrame(for: to,
                                             inBounds: context.containerView.bounds,
                                             alignmentEdge: (direction.value == .forward) ? foreAlignmentEdge : nil) {
        finalFrame = preferredFrame
      } else {
        finalFrame = context.finalFrame(for: to)
      }
      if !finalFrame.isEmpty {
        to.view.frame = finalFrame
      }

      switch direction.value {
      case .forward:
        context.containerView.addSubview(to.view)

      case .backward:
        if to.view.superview == nil {
          context.containerView.insertSubview(to.view, at: 0)
        }
      }
      to.view.layoutIfNeeded()
    }

    self.runtime = MotionRuntime(containerView: containerView())
    self.replicator.containerView = containerView()

    let terminators = transition.willBeginTransition(withContext: self, runtime: self.runtime)
    runtime.whenAllAtRest(terminators) { [weak self] in
      self?.terminate()
    }
  }

  private func terminate() {
    guard runtime != nil else { return }
    let completedInOriginalDirection = direction.value == initialDirection

    // UIKit container view controllers will replay their transition animation if the transition
    // percentage is exactly 0 or 1, so we fake being super close to these values in order to avoid
    // this flickering animation.
    if completedInOriginalDirection {
      context.updateInteractiveTransition(0.999)
      context.finishInteractiveTransition()
    } else {
      context.updateInteractiveTransition(0.001)
      context.cancelInteractiveTransition()
    }
    context.completeTransition(completedInOriginalDirection)

    runtime = nil
    transition = nil

    delegate?.transitionDidComplete(withContext: self)
  }
}

protocol TransitionDelegate: class {
  func transitionDidComplete(withContext ctx: TransitionContext)
}

extension TransitionDirection: Invertible {
  public func inverted() -> TransitionDirection {
    return self == .forward ? .backward : .forward
  }
}
