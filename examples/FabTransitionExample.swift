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

class FabTransitionExampleViewController: ExampleViewController, TransitionContextViewRetriever {

  var actionButton: UIButton!
  override func viewDidLoad() {
    super.viewDidLoad()

    actionButton = UIButton(type: .custom)
    actionButton.backgroundColor = .primaryColor
    actionButton.bounds = .init(x: 0, y: 0, width: 50, height: 50)
    actionButton.layer.cornerRadius = actionButton.bounds.width / 2
    actionButton.layer.position = CGPoint(x: view.bounds.width - actionButton.bounds.width / 2 - 24,
                                        y: view.bounds.height - actionButton.bounds.height / 2 - 24)
    actionButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
    actionButton.layer.shadowOpacity = 0.5
    actionButton.layer.shadowOffset = .init(width: 0, height: 3)
    actionButton.layer.shadowRadius = 2
    actionButton.layer.shadowPath = UIBezierPath(ovalIn: actionButton.bounds).cgPath
    view.addSubview(actionButton)

    actionButton.addTarget(self, action: #selector(didTap), for: .touchUpInside)
  }

    @objc func didTap() {
    let vc = ModalViewController()
    vc.transitionController.transition = CircularRevealTransition()
    present(vc, animated: true)
  }

  func contextViewForTransition(foreViewController: UIViewController) -> UIView? {
    return actionButton
  }

  override func exampleInformation() -> ExampleInfo {
    return .init(title: type(of: self).catalogBreadcrumbs().last!,
                 instructions: "Tap the floating action button to start a transition.")
  }
}

private class ModalViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .primaryColor

    let exampleView = center(createExampleView(), within: view)
    exampleView.backgroundColor = .white
    view.addSubview(exampleView)

    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
  }

    @objc func didTap() {
    dismiss(animated: true)
  }
}

let floodFillOvershootRatio: CGFloat = 1.2

private class CircularRevealTransition: TransitionWithTermination {

  // TODO: Support for transient views.
  var floodFillView: UIView!
  var foreViewLayer: CALayer!

  func didEndTransition(withContext ctx: TransitionContext, runtime: MotionRuntime) {
    floodFillView.removeFromSuperview()
    foreViewLayer.mask = nil
  }

  func willBeginTransition(withContext ctx: TransitionContext, runtime: MotionRuntime) -> [Stateful] {
    foreViewLayer = ctx.fore.view.layer

    let contextView = ctx.contextView()!

    floodFillView = UIView()
    floodFillView.backgroundColor = contextView.backgroundColor
    floodFillView.layer.cornerRadius = contextView.layer.cornerRadius
    floodFillView.layer.shadowColor = contextView.layer.shadowColor
    floodFillView.layer.shadowOffset = contextView.layer.shadowOffset
    floodFillView.layer.shadowOpacity = contextView.layer.shadowOpacity
    floodFillView.layer.shadowRadius = contextView.layer.shadowRadius
    floodFillView.layer.shadowPath = contextView.layer.shadowPath
    floodFillView.frame = ctx.containerView().convert(contextView.bounds, from: contextView)
    ctx.containerView().addSubview(floodFillView)

    let maskLayer = CAShapeLayer()
    let maskPathBounds = floodFillView.frame.insetBy(dx: 1, dy: 1)
    maskLayer.path = UIBezierPath(ovalIn: maskPathBounds).cgPath
    ctx.fore.view.layer.mask = maskLayer

    // The distance from the center of the context view to the top left of the screen is the desired
    // radius of the circle fill. If the context view is placed in a different corner of the screen
    // then this will need to be replaced with an algorithm that determines the furthest corner from
    // the center of the view.
    let outerRadius = CGFloat(sqrt(floodFillView.center.x * floodFillView.center.x + floodFillView.center.y * floodFillView.center.y)) * floodFillOvershootRatio

    let expandedSize = CGSize(width: outerRadius * 2, height: outerRadius * 2)

    let expansion = tween(back: floodFillView.bounds.size, fore: expandedSize, ctx: ctx)
    let fadeOut = tween(back: CGFloat(1), fore: CGFloat(0), ctx: ctx)
    let radius = tween(back: floodFillView.layer.cornerRadius, fore: outerRadius, ctx: ctx)

    let foreShadowPath = CGRect(origin: .zero(), size: expandedSize)
    let shadowPath = tween(back: floodFillView.layer.shadowPath!, fore: UIBezierPath(ovalIn: foreShadowPath).cgPath, ctx: ctx)

    let floodLayer = runtime.get(floodFillView).layer
    runtime.add(expansion, to: floodLayer.size)
    runtime.add(fadeOut, to: floodLayer.opacity)
    runtime.add(radius, to: floodLayer.cornerRadius)
    runtime.add(shadowPath, to: floodLayer.shadowPath)

    let shiftIn = tween(back: ctx.fore.view.layer.position.y + 40, fore: ctx.fore.view.layer.position.y, ctx: ctx)
    runtime.add(shiftIn, to: runtime.get(ctx.fore.view).layer.positionY)

    let maskShiftIn = tween(back: CGFloat(-40), fore: CGFloat(0), ctx: ctx)
    runtime.add(maskShiftIn, to: runtime.get(maskLayer).positionY)

    let foreMaskBounds = CGRect(x: floodFillView.center.x - outerRadius,
                                y: floodFillView.center.y - outerRadius,
                                width: outerRadius * 2,
                                height: outerRadius * 2)
    let maskReveal = tween(back: maskLayer.path!, fore: UIBezierPath(ovalIn: foreMaskBounds).cgPath, ctx: ctx)
    runtime.add(maskReveal, to: runtime.get(maskLayer).path)

    runtime.add(Hidden(), to: contextView)

    return [expansion, fadeOut, radius, shadowPath, shiftIn]
  }

  private func tween<T>(back: T, fore: T, ctx: TransitionContext) -> Tween<T> {
    let values: [T]
    if ctx.direction.value == .forward {
      values = [back, fore]
    } else {
      values = [fore, back]
    }
    return Tween(duration: 0.4 * simulatorDragCoefficient(), values: values)
  }
}

// TODO: The need here is we want to hide a given view will the transition is active. This
// implementation does not register a stream with the runtime.
private class Hidden: Interaction {
  deinit {
    for view in hiddenViews {
      view.isHidden = false
    }
  }
  func add(to view: UIView, withRuntime runtime: MotionRuntime, constraints: NoConstraints) {
    view.isHidden = true
    hiddenViews.insert(view)
  }
  var hiddenViews = Set<UIView>()
}
