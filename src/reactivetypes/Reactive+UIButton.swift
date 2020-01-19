/*
 Copyright 2017-present The Material Motion Authors. All Rights Reserved.

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
 A reactive button target exposes streams for certain button events.
 */
public final class ReactiveButtonTarget: NSObject {
  public init(_ button: UIButton) {
    super.init()

    button.addTarget(self, action: #selector(didEnterEvent),
                     for: [.touchDown, .touchDragInside])
    button.addTarget(self, action: #selector(didExitEvent),
                     for: [.touchUpInside, .touchUpOutside, .touchDragOutside])
  }

  // MARK: Streams

  /**
   Emits true when the button should be highlighted and false when it should not.
   */
  public var didHighlight: MotionObservable<Bool> {
    return MotionObservable { observer in
      self.didHighlightObservers.append(observer)
      return {
        if let index = self.didHighlightObservers.firstIndex(where: { $0 === observer }) {
          self.didHighlightObservers.remove(at: index)
        }
      }
    }
  }

    @objc func didEnterEvent(_ button: UIButton) {
    didHighlightObservers.forEach { $0.next(true) }
  }
    @objc func didExitEvent(_ button: UIButton) {
    didHighlightObservers.forEach { $0.next(false) }
  }
  private var didHighlightObservers: [MotionObserver<Bool>] = []
}
