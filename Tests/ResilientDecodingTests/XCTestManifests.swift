// MIT License
//
// Copyright (c) 2020 Airbnb
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#if !canImport(ObjectiveC)
import XCTest

extension MemoryTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__MemoryTests = [
        ("testNoOverheadInRelease", testNoOverheadInRelease),
    ]
}

extension ResilientArrayTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ResilientArrayTests = [
        ("testDecodesNullValue", testDecodesNullValue),
        ("testDecodesValidInputWithoutErrors", testDecodesValidInputWithoutErrors),
        ("testDecodesWhenMissingKeys", testDecodesWhenMissingKeys),
        ("testResilientlyDecodesArrayWithInvalidElements", testResilientlyDecodesArrayWithInvalidElements),
        ("testResilientlyDecodesIncorrectType", testResilientlyDecodesIncorrectType),
    ]
}

extension ResilientDecodingErrorReporterTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ResilientDecodingErrorReporterTests = [
        ("testDebugDescription", testDebugDescription),
    ]
}

extension ResilientOptionalTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ResilientOptionalTests = [
        ("testDecodesNullValueWithoutErrors", testDecodesNullValueWithoutErrors),
        ("testDecodesValidInputWithoutErrors", testDecodesValidInputWithoutErrors),
        ("testDecodesWhenMissingKeyWithoutErrors", testDecodesWhenMissingKeyWithoutErrors),
        ("testResilientlyDecodesInvalidValue", testResilientlyDecodesInvalidValue),
    ]
}

extension ResilientRawRepresentableArrayTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ResilientRawRepresentableArrayTests = [
        ("testDecodesNullValuesWithoutErrors", testDecodesNullValuesWithoutErrors),
        ("testDecodesValidInputWithoutErrors", testDecodesValidInputWithoutErrors),
        ("testDecodesWhenMissingKeysWithoutErrors", testDecodesWhenMissingKeysWithoutErrors),
        ("testResilientlyDecodesInvalidCases", testResilientlyDecodesInvalidCases),
        ("testResilientlyDecodesNovelCases", testResilientlyDecodesNovelCases),
    ]
}

extension ResilientRawRepresentableEnumTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__ResilientRawRepresentableEnumTests = [
        ("testDecodesMissingOptionalValuesWithoutErrors", testDecodesMissingOptionalValuesWithoutErrors),
        ("testDecodesNullOptionalValuesWithoutErrors", testDecodesNullOptionalValuesWithoutErrors),
        ("testDecodesValidCasesWithoutErrors", testDecodesValidCasesWithoutErrors),
        ("testResilientlyDecodesInvalidCases", testResilientlyDecodesInvalidCases),
        ("testResilientlyDecodesMissingValues", testResilientlyDecodesMissingValues),
        ("testResilientlyDecodesNovelCases", testResilientlyDecodesNovelCases),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MemoryTests.__allTests__MemoryTests),
        testCase(ResilientArrayTests.__allTests__ResilientArrayTests),
        testCase(ResilientDecodingErrorReporterTests.__allTests__ResilientDecodingErrorReporterTests),
        testCase(ResilientOptionalTests.__allTests__ResilientOptionalTests),
        testCase(ResilientRawRepresentableArrayTests.__allTests__ResilientRawRepresentableArrayTests),
        testCase(ResilientRawRepresentableEnumTests.__allTests__ResilientRawRepresentableEnumTests),
    ]
}
#endif
