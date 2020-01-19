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

class PushBackTransitionExampleViewController: ExampleViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
  }

    @objc func didTap() {
    let vc = ModalViewController()
    present(vc, animated: true)
  }

  override func exampleInformation() -> ExampleInfo {
    return .init(title: type(of: self).catalogBreadcrumbs().last!,
                 instructions: "Tap to present a modal transition.")
  }
}

private class ModalViewController: UIViewController {

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

    transitionController.transition = PushBackTransition()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .primaryColor

    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
  }

    @objc func didTap() {
    dismiss(animated: true)
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
}

private class PushBackTransition: Transition {

  func willBeginTransition(withContext ctx: TransitionContext, runtime: MotionRuntime) -> [Stateful] {
    let bounds = ctx.containerView().bounds
    let backPosition = bounds.maxY + ctx.fore.view.bounds.height / 2
    let forePosition = bounds.midY

    let movement = TransitionSpring(back: backPosition, fore: forePosition, direction: ctx.direction)

    let yPosition = runtime.get(ctx.fore.view.layer).positionY

    runtime.connect(yPosition.rewriteRange(start: movement.backwardDestination,
                                           end: movement.forwardDestination,
                                           destinationStart: CGFloat(1),
                                           destinationEnd: CGFloat(0.95)),
                    to: runtime.get(ctx.back.view.layer).scale)

    runtime.add(movement, to: yPosition)

    return [movement]
  }
}
