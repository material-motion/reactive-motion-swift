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

class MaterialExpansionExampleViewController: ExampleViewController {

  var runtime: MotionRuntime!

  override func viewDidLoad() {
    super.viewDidLoad()

    let square = center(createExampleSquareView(), within: view)
    square.clipsToBounds = true
    view.addSubview(square)

    let maskView = UIView(frame: view.bounds)
    maskView.isUserInteractionEnabled = false
    let mask = CALayer()
    mask.backgroundColor = UIColor.black.cgColor
    mask.frame = square.frame
    maskView.layer.mask = mask
    view.addSubview(maskView)

    let flood = UIView(frame: square.bounds.insetBy(dx: -square.bounds.width, dy: -square.bounds.height))
    flood.layer.cornerRadius = flood.bounds.width / 2
    flood.backgroundColor = .white
    maskView.addSubview(flood)

    runtime = MotionRuntime(containerView: view)

    let direction = createProperty(withInitialValue: TransitionDirection.backward)

    let tap = runtime.get(UITapGestureRecognizer())

    let widthExpansion = TransitionTween(duration: 0.375,
                                         forwardValues: [square.bounds.width, square.bounds.width * 2],
                                         direction: direction,
                                         forwardKeyPositions: [0, 0.8],
                                         system: coreAnimation)
    let heightExpansion = TransitionTween(duration: 0.375,
                                          forwardValues: [square.bounds.height, square.bounds.height * 2],
                                          direction: direction,
                                          forwardKeyPositions: [0.2, 1.0],
                                          system: coreAnimation)

    let floodExpansion = Tween<CGFloat>(duration: 0.375, values: [0, 1])
    floodExpansion.timingFunctions.value = [CAMediaTimingFunction(name: .easeOut)]
    let fadeOut = Tween<CGFloat>(duration: 0.375, values: [0.75, 0])
    fadeOut.offsets.value = [0.2, 1]

    runtime.add(SetPositionOnTap(.withExistingRecognizer(tap.gestureRecognizer)),
                to: runtime.get(flood.layer).position)
    runtime.add(floodExpansion, to: runtime.get(flood.layer).scale)
    runtime.add(fadeOut, to: runtime.get(flood.layer).opacity)

    for interaction in [floodExpansion, fadeOut] {
      runtime.start(interaction, whenActive: tap)
    }

    runtime.connect(tap.whenRecognitionState(is: .recognized).rewriteTo(direction).inverted(), to: direction)

    // Interactions are enabled by default, but in this case we don't want our transition to start
    // until the first tap. Without this setup the runtime would immediately perform a backward
    // transition.
    let startTransition = createProperty(withInitialValue: false)
    for interaction in [widthExpansion, heightExpansion] {
      runtime.connect(startTransition, to: interaction.enabled)
    }
    runtime.connect(tap.whenRecognitionState(is: .recognized).rewriteTo(true), to: startTransition)

    runtime.add(widthExpansion, to: runtime.get(square.layer).width)
    runtime.add(heightExpansion, to: runtime.get(square.layer).height)

    // Ensure that our mask always tracks the square.
    runtime.connect(runtime.get(square.layer).width, to: runtime.get(mask).width)
    runtime.connect(runtime.get(square.layer).height, to: runtime.get(mask).height)
  }

  override func exampleInformation() -> ExampleInfo {
    return .init(title: type(of: self).catalogBreadcrumbs().last!,
                 instructions: "Tap anywhere to create an ink ripple.")
  }
}
