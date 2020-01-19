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
import IndefiniteObservable
import MaterialMotion

protocol TimelineViewDelegate: NSObjectProtocol {
  func timelineView(_ timelineView: TimelineView, didChangeSliderValue sliderValue: CGFloat)
  func timelineViewDidTogglePause(_ timelineView: TimelineView)
}

class TimelineView: UIView {

  weak var delegate: TimelineViewDelegate?

  var timeline: Timeline? {
    didSet {
      pausedSubscription = timeline?.paused.subscribeToValue { [weak self] paused in
        self?.toggle.setTitle(paused ? "▶" : "❙❙", for: .normal)
      }
    }
  }
  private var pausedSubscription: Subscription?

   override init(frame: CGRect) {
    super.init(frame: frame)

    bgView = UIView(frame: .zero)
    bgView.backgroundColor = UIColor.init(white: 0.95, alpha: 1)
    self.addSubview(bgView)

    slider = UISlider(frame: .zero)
    slider.tintColor = .primaryColor
    slider.addTarget(self, action: #selector(didSlide), for: .valueChanged)
    self.addSubview(slider)

    toggle = UIButton(type: .custom)
    toggle.setTitle("▶", for: .normal)
    toggle.setTitleColor(.black, for: .normal)
    toggle.addTarget(self, action: #selector(didToggle), for: .touchUpInside)
    self.addSubview(toggle)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    bgView.frame = .init(x: 0, y: 20, width: bounds.size.width, height: bounds.size.height - 20)

    let center = CGPoint(x: bounds.size.width / 2.0, y: bounds.size.height / 2.0)
    slider.frame = .init(x: 16, y: 0, width: frame.width - 32, height: 40)
    toggle.frame = .init(x: center.x - 16, y: center.y - 16 + 12, width: 32, height: 32)
  }

  override public func sizeThatFits(_ size: CGSize) -> CGSize {
    return .init(width: size.width, height: 84)
  }

    @objc func didSlide(_ slider: UISlider) {
    delegate?.timelineView(self, didChangeSliderValue: CGFloat(slider.value))
  }

    @objc func didToggle(_ button: UIButton) {
    delegate?.timelineViewDidTogglePause(self)
  }

  private var bgView: UIView!
  private var slider: UISlider!
  private var toggle: UIButton!
}
