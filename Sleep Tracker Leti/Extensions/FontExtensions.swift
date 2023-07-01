
import SwiftUI

extension Font {
    static func montserrat(_ size: CGFloat = 24) -> Font {
        .custom("Montserrat", size: size)
    }
}

import Foundation
import SwiftUI

struct SavingsDataPoint: Identifiable {
    let month: String
    let value: Double
    var id = UUID()
}

struct TempSleepInterval {
    var begin: Date?
    var end: Date?
    
    init(begin: Date?, end: Date?) {
            self.begin = begin
            self.end = end
        }
}
