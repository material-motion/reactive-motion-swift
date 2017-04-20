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

import UIKit
import MaterialMotion

class InteractivePushBackTransitionExampleViewController: ExampleViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
  }

  func didTap() {
    let vc = ModalViewController()
    present(vc, animated: true)
  }

  override func exampleInformation() -> ExampleInfo {
    return .init(title: type(of: self).catalogBreadcrumbs().last!,
                 instructions: "Tap to present a modal transition.")
  }
}

private class ModalViewController: UIViewController, UIGestureRecognizerDelegate {

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

    transitionController.transitionType = PushBackTransition.self
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var scrollView: UIScrollView!
  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .primaryColor

    scrollView = UIScrollView(frame: view.bounds)
    scrollView.contentSize = .init(width: view.bounds.width, height: view.bounds.height * 10)
    view.addSubview(scrollView)

    let pan = UIPanGestureRecognizer()
    pan.delegate = transitionController.topEdgeDismisserDelegate(for: scrollView)
    transitionController.dismissWhenGestureRecognizerBegins(pan)
    scrollView.panGestureRecognizer.require(toFail: pan)
    view.addGestureRecognizer(pan)
  }
}

private class PushBackTransition: Transition {

  required init() {}

  func willBeginTransition(withContext ctx: TransitionContext, runtime: MotionRuntime) -> [Stateful] {
    let draggable = Draggable(withFirstGestureIn: ctx.gestureRecognizers)

    runtime.add(ChangeDirection(withVelocityOf: draggable.nextGestureRecognizer, whenNegative: .forward),
                to: ctx.direction)

    let bounds = ctx.containerView().bounds
    let backPosition = CGPoint(x: bounds.midX, y: bounds.maxY + ctx.fore.view.bounds.height / 2)
    let forePosition = CGPoint(x: bounds.midX, y: bounds.midY)
    let movement = TransitionSpring(back: backPosition,
                                    fore: forePosition,
                                    direction: ctx.direction)

    let scale = runtime.get(ctx.back.view.layer).scale

    let tossable = Tossable(spring: movement, draggable: draggable)

    runtime.connect(runtime.get(ctx.fore.view.layer).position.y()
      .rewriteRange(start: movement.backwardDestination.y,
                    end: movement.forwardDestination.y,
                    destinationStart: 1,
                    destinationEnd: 0.95),
                    to: scale)

    runtime.add(tossable, to: ctx.fore.view) { $0.xLocked(to: bounds.midX) }

    return [tossable]
  }
}
