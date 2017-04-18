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

import XCTest
import MaterialMotion

class delayTests: XCTestCase {

  func testValueIsDelayed() {
    let property = createProperty()

    var hasReceived = false
    let didReceiveValue = expectation(description: "Did receive value")
    let subscription = property.delay(by: 0.01).subscribeToValue { value in
      XCTAssertEqual(value, 0)
      didReceiveValue.fulfill()
      hasReceived = true
    }

    XCTAssertFalse(hasReceived)

    waitForExpectations(timeout: 0.1)

    subscription.unsubscribe()
  }

  func testValueIsDelayedUsingDispatchTimeInterval() {
    let property = createProperty()
    
    var hasReceived = false
    let didReceiveValue = expectation(description: "Did receive value")
    let subscription = property.delay(by: .milliseconds(500)).subscribeToValue { value in
      XCTAssertEqual(value, 0)
      didReceiveValue.fulfill()
      hasReceived = true
    }
    
    XCTAssertFalse(hasReceived)
    
    waitForExpectations(timeout: 0.5)
    
    subscription.unsubscribe()
  }
  
  func testValueIsNotReceivedWithoutSubscription() {
    let property = createProperty()

    let _ = property.delay(by: 0.01).subscribeToValue { value in
      assertionFailure("Should not be received.")
    }

    let delay = expectation(description: "Delay")
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(Int(0.05 * 1000))) {
      delay.fulfill()
    }

    waitForExpectations(timeout: 0.1)
  }
}
