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

/** Create a core animation tween system for a Tween plan. */
public func coreAnimation(_ tween: PathTweenShadow) -> MotionObservable<CGPoint> {
  return MotionObservable { observer in

    var subscriptions: [Subscription] = []
    let key = NSUUID().uuidString
    var activeAnimations = Set<CAKeyframeAnimation>()

    let checkAndEmit = {
      subscriptions.append(tween.path.subscribeToValue { pathValue in

        let animation = CAKeyframeAnimation()
        activeAnimations.insert(animation)
        animation.path = pathValue

        observer.next(pathValue.getAllPoints().last!)

        guard let duration = tween.duration._read() else {
          return
        }
        animation.beginTime = TimeInterval(tween.delay.value)
        animation.duration = CFTimeInterval(duration)

        tween.state.value = .active

        var info = CoreAnimationChannelAdd(animation: animation, key: key, onCompletion: {
          activeAnimations.remove(animation)
          if activeAnimations.count == 0 {
            tween.state.value = .atRest
          }
        })
        info.timeline = tween.timeline
        observer.coreAnimation?(.add(info))

        let view = UIView()
        let brushLayer = CAShapeLayer()
        brushLayer.opacity = 0.5
        brushLayer.lineWidth = 2
        brushLayer.strokeStart = 0
        brushLayer.strokeEnd = 1
        brushLayer.lineCap = .round
        brushLayer.fillColor = UIColor.white.withAlphaComponent(0).cgColor
        brushLayer.strokeColor = UIColor(red: 0xC5/255.0, green: 0x11/255.0, blue: 0x62/255.0, alpha: 1).cgColor
        brushLayer.path = pathValue

        if let timeline = tween.timeline {
          if timeline.paused.value {
            brushLayer.lineDashPattern = [2, 3]
          } else {
            brushLayer.lineDashPattern = nil
            brushLayer.strokeStart = 1

            let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
            strokeEndAnimation.duration = animation.duration
            strokeEndAnimation.timingFunction = animation.timingFunction
            strokeEndAnimation.fromValue = 0
            strokeEndAnimation.toValue = 1
            brushLayer.add(strokeEndAnimation, forKey: "strokeEnd")

            let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
            strokeStartAnimation.duration = animation.duration * 0.75
            strokeStartAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
            strokeStartAnimation.fromValue = 0
            strokeStartAnimation.toValue = 1
            strokeStartAnimation.beginTime = CACurrentMediaTime() + animation.duration * 0.75
            strokeStartAnimation.fillMode = CAMediaTimingFillMode.backwards
            brushLayer.add(strokeStartAnimation, forKey: "strokeStart")

            let lineWidthAnimation = CABasicAnimation(keyPath: "lineWidth")
            lineWidthAnimation.duration = animation.duration * 1.75
            lineWidthAnimation.fromValue = 3
            lineWidthAnimation.toValue = 0
            brushLayer.add(lineWidthAnimation, forKey: "lineWidth")
          }
        }

        view.layer.addSublayer(brushLayer)
        observer.visualization?(view)
      })
    }

    let activeSubscription = tween.enabled.dedupe().subscribeToValue { enabled in
      if enabled {
        checkAndEmit()
      } else {
        observer.coreAnimation?(.remove(key))
        activeAnimations.removeAll()
        tween.state.value = .atRest
      }
    }

    return {
      observer.coreAnimation?(.remove(key))
      subscriptions.forEach { $0.unsubscribe() }
      activeSubscription.unsubscribe()
    }
  }
}

extension CGPath {

  // Iterates over each registered point in the CGPath. We must use @convention notation to bridge
  // between the swift and objective-c block APIs.
  // Source: http://stackoverflow.com/questions/12992462/how-to-get-the-cgpoints-of-a-cgpath#36374209
  func forEach( body: @escaping @convention(block) (CGPathElement) -> Void) {
      typealias Body = @convention(block) (CGPathElement) -> Void
      let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { (info, element) in
          let body = unsafeBitCast(info, to: Body.self)
          body(element.pointee)
      }
      //print(MemoryLayout.size(ofValue: body))
      let unsafeBody = unsafeBitCast(body, to: UnsafeMutableRawPointer.self)
      self.apply(info: unsafeBody, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
  }

  fileprivate func getAllPoints() -> [CGPoint] {
    var arrayPoints: [CGPoint] = []
    self.forEach { element in
      switch (element.type) {
      case .moveToPoint:
        arrayPoints.append(element.points[0])
      case .addLineToPoint:
        arrayPoints.append(element.points[0])
      case .addQuadCurveToPoint:
        arrayPoints.append(element.points[0])
        arrayPoints.append(element.points[1])
      case .addCurveToPoint:
        arrayPoints.append(element.points[0])
        arrayPoints.append(element.points[1])
        arrayPoints.append(element.points[2])
      default: break
      }
    }
    return arrayPoints
  }
}
