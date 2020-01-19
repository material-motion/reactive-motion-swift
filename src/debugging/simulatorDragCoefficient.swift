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

// This is a simulator-only API for detecting simulator slow-motion animations being enabled.
// simulatorDragCoefficient() returns a value that is greater than 1 when slow-motion is enabled.

#if targetEnvironment(simulator)
  @_silgen_name("UIAnimationDragCoefficient") func UIAnimationDragCoefficient() -> Float
  public func simulatorDragCoefficient() -> CGFloat {
    return CGFloat(UIAnimationDragCoefficient())
  }
#else
  public func simulatorDragCoefficient() -> CGFloat {
    return 1
  }
#endif
