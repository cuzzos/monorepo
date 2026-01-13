import SwiftUI

/// Static piano keyboard strip (visual only for v1)
struct KeyboardStrip: View {
    private let whiteKeyCount = 14
    private let blackKeyPattern = [true, true, false, true, true, true, false]
    
    var body: some View {
        GeometryReader { geometry in
            let whiteKeyWidth = geometry.size.width / CGFloat(whiteKeyCount)
            let blackKeyWidth = whiteKeyWidth * 0.6
            let blackKeyHeight = geometry.size.height * 0.6
            
            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: 1) {
                    ForEach(0..<whiteKeyCount, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.9))
                    }
                }
                
                // Black keys
                HStack(spacing: 0) {
                    ForEach(0..<whiteKeyCount, id: \.self) { index in
                        let patternIndex = index % 7
                        let hasBlackKey = blackKeyPattern[patternIndex]
                        
                        ZStack(alignment: .trailing) {
                            Color.clear
                                .frame(width: whiteKeyWidth)
                            
                            if hasBlackKey && index < whiteKeyCount - 1 {
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: blackKeyWidth, height: blackKeyHeight)
                                    .offset(x: blackKeyWidth / 2)
                            }
                        }
                    }
                }
            }
        }
        .frame(height: 54)
        .clipShape(.rect(cornerRadius: 4))
    }
}

#Preview {
    KeyboardStrip()
        .background(Color(hex: 0x0B0C0E))
}

