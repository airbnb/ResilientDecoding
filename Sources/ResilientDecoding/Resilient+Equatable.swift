// Created by Suyeol Jeon on 7/16/20.
// Copyright © 2020 Airbnb Inc.

extension Resilient: Equatable where Value: Equatable {
  public static func == (lhs: Resilient<Value>, rhs: Resilient<Value>) -> Bool {
    return lhs.wrappedValue == rhs.wrappedValue
  }
}
