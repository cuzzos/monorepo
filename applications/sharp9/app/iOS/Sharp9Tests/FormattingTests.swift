import Testing
import Foundation
@testable import Sharp9

struct FormattingTests {
    // MARK: - formatTime Tests

    @Test("formatTime formats seconds as MM:SS.xx with zero-padding")
    func testFormatTime_zeroPadding() {
        #expect(Formatting.formatTime(0) == "00:00.00")
        #expect(Formatting.formatTime(5.5) == "00:05.50")
        #expect(Formatting.formatTime(65.5) == "01:05.50")
        #expect(Formatting.formatTime(125.25) == "02:05.25")
        #expect(Formatting.formatTime(3599.99) == "59:59.99")
    }

    @Test("formatTime handles edge cases")
    func testFormatTime_edgeCases() {
        #expect(Formatting.formatTime(0.01) == "00:00.01")
        #expect(Formatting.formatTime(59.99) == "00:59.99")
        #expect(Formatting.formatTime(60) == "01:00.00")
        #expect(Formatting.formatTime(61.5) == "01:01.50")
        #expect(Formatting.formatTime(3599.99) == "59:59.99")
    }

    @Test("formatTime handles negative values by treating as zero")
    func testFormatTime_negativeValues() {
        #expect(Formatting.formatTime(-5.5) == "00:00.00")
        #expect(Formatting.formatTime(-1) == "00:00.00")
    }

    @Test("formatTime handles fractional seconds correctly")
    func testFormatTime_fractionalSeconds() {
        #expect(Formatting.formatTime(1.0) == "00:01.00")
        #expect(Formatting.formatTime(1.1) == "00:01.10")
        #expect(Formatting.formatTime(1.01) == "00:01.01")
        #expect(Formatting.formatTime(1.001) == "00:01.00") // Rounds down
        #expect(Formatting.formatTime(1.999) == "00:02.00")
    }

    @Test("formatTime handles large minutes with zero-padding")
    func testFormatTime_largeMinutes() {
        #expect(Formatting.formatTime(600) == "10:00.00") // 10 minutes
        #expect(Formatting.formatTime(660) == "11:00.00") // 11 minutes
        #expect(Formatting.formatTime(3599) == "59:59.00") // 59:59
        #expect(Formatting.formatTime(3600) == "60:00.00") // 60 minutes
    }
}
