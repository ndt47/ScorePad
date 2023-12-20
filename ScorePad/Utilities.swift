import SwiftUI

extension View {
    static var isIPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return true
        #endif
    }
    
    static var isIPhone: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone
        #else
        return true
        #endif
    }
}
