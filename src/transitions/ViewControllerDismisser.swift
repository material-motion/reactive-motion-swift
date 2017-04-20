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

/**
 A view controller dismisser is responsible for initiating a view controller dismiss transition in
 reaction to a gesture recognizer entering its began or recognized state.

 Gesture recognizers provided to a dismisser will be made available to the transition instance via
 the TransitionContext's `gestureRecognizers` property.
 */
public final class ViewControllerDismisser {

  /**
   Start a dismiss transition when the given gesture recognizer enters its began or recognized
   state.

   The provided gesture recognizer will be made available to the transition instance via the
   TransitionContext's `gestureRecognizers` property.
   */
  public func dismissWhenGestureRecognizerBegins(_ gestureRecognizer: UIGestureRecognizer) {
    gestureRecognizer.addTarget(self, action: #selector(gestureRecognizerDidChange))

    if gestureRecognizer.delegate == nil {
      gestureRecognizer.delegate = gestureDelegate
    }

    gestureDelegate.gestureRecognizers.insert(gestureRecognizer)
  }

  public func disableSimultaneousRecognition(of gestureRecognizer: UIGestureRecognizer) {
    gestureDelegate.soloGestureRecognizers.insert(gestureRecognizer)
  }

  /**
   Returns a gesture recognizer delegate that will allow the gesture recognizer to begin only if the
   provided scroll view is scrolled to the top of its content.

   The returned delegate implements gestureRecognizerShouldBegin.
   */
  public func topEdgeDismisserDelegate(for scrollView: UIScrollView) -> UIGestureRecognizerDelegate {
    for delegate in scrollViewTopEdgeDismisserDelegates {
      if delegate.scrollView == scrollView {
        return delegate
      }
    }
    let delegate = ScrollViewTopEdgeDismisserDelegate()
    delegate.scrollView = scrollView
    scrollViewTopEdgeDismisserDelegates.append(delegate)
    return delegate
  }

  @objc func gestureRecognizerDidChange(_ gestureRecognizer: UIGestureRecognizer) {
    if gestureRecognizer.state == .began || gestureRecognizer.state == .recognized {
      delegate?.dismiss()
    }
  }

  weak var delegate: ViewControllerDismisserDelegate?

  public var gestureRecognizers: Set<UIGestureRecognizer> {
    set { gestureDelegate.gestureRecognizers = newValue }
    get { return gestureDelegate.gestureRecognizers }
  }

  init(gestureDelegate: GestureDelegate) {
    self.gestureDelegate = gestureDelegate
  }

  private var gestureDelegate: GestureDelegate
  private var scrollViewTopEdgeDismisserDelegates: [ScrollViewTopEdgeDismisserDelegate] = []
}

private final class ScrollViewTopEdgeDismisserDelegate: NSObject, UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let pan = gestureRecognizer as? UIPanGestureRecognizer, let scrollView = scrollView {
      return pan.translation(in: pan.view).y > 0
        && scrollView.contentOffset.y <= -scrollView.contentInset.top
    }
    return false
  }

  weak var scrollView: UIScrollView?
}

final class GestureDelegate: NSObject, UIGestureRecognizerDelegate {
  var gestureRecognizers = Set<UIGestureRecognizer>()
  var soloGestureRecognizers = Set<UIGestureRecognizer>()

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    if soloGestureRecognizers.contains(gestureRecognizer) || soloGestureRecognizers.contains(otherGestureRecognizer) {
      return false
    }
    return gestureRecognizers.contains(gestureRecognizer)
      && gestureRecognizers.contains(otherGestureRecognizer)
  }
}

protocol ViewControllerDismisserDelegate: class {
  func dismiss()
}
