// Created by Suyeol Jeon on 7/16/20.
// Copyright © 2020 Airbnb Inc.

extension Resilient: Hashable where Value: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.wrappedValue)
  }
}
