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

class ModalDialogExampleViewController: ExampleViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
  }

  func didTap() {
    let vc = ModalDialogViewController()
    present(vc, animated: true)
  }

  func tapToDismiss() {
    dismiss(animated: true)
  }

  override func exampleInformation() -> ExampleInfo {
    return .init(title: type(of: self).catalogBreadcrumbs().last!,
                 instructions: "Tap to present a modal dialog.")
  }
}

class ModalDialogViewController: UIViewController {

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

    transitionController.transitionType = ModalDialogTransition.self
    preferredContentSize = .init(width: 200, height: 200)
    modalPresentationStyle = .overCurrentContext
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .primaryColor

    view.layer.cornerRadius = 5
    view.layer.shadowColor = UIColor(white: 0, alpha: 0.4).cgColor
    view.layer.shadowRadius = 5
    view.layer.shadowOpacity = 1
    view.layer.shadowOffset = .init(width: 0, height: 2)
  }
}

class ModalDialogTransition: SelfDismissingTransition {

  required init() {}

  func willBeginTransition(withContext ctx: TransitionContext, runtime: MotionRuntime) -> [Stateful] {
    let size = ctx.fore.view.frame.size
    let bounds = ctx.containerView().bounds
    let backPosition = CGPoint(x: bounds.midX, y: bounds.maxY + size.height * 3 / 4)
    let forePosition = ctx.fore.view.layer.position

    let reactiveForeLayer = runtime.get(ctx.fore.view.layer)
    let position = reactiveForeLayer.position

    let draggable = Draggable(withFirstGestureIn: ctx.gestureRecognizers)

    let gesture = runtime.get(draggable.nextGestureRecognizer)
    let centerY = ctx.containerView().bounds.height / 2.0

    runtime.add(ChangeDirection(withVelocityOf: draggable.nextGestureRecognizer, whenNegative: .forward),
                to: ctx.direction)

    runtime.connect(gesture
      .velocityOnReleaseStream()
      .y()
      .thresholdRange(min: -100, max: 100)
      .rewrite([.within: position.y().threshold(centerY).rewrite([.below: .forward,
                                                                  .above: .backward])]),
                to: ctx.direction)

    let movement = TransitionSpring(back: backPosition,
                                    fore: forePosition,
                                    direction: ctx.direction)
    let tossable = Tossable(spring: movement, draggable: draggable)
    runtime.add(tossable, to: ctx.fore.view)

    return [tossable.spring]
  }

  static func willPresent(fore: UIViewController, dismisser: ViewControllerDismisser) {
    let tap = UITapGestureRecognizer()
    fore.view.addGestureRecognizer(tap)
    dismisser.dismissWhenGestureRecognizerBegins(tap)
    let pan = UIPanGestureRecognizer()
    fore.view.addGestureRecognizer(pan)
    dismisser.dismissWhenGestureRecognizerBegins(pan)
  }
}
