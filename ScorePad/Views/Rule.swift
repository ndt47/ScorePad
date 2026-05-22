//
//  Rule.swift
//  ScorePad
//
//  Created by Nathan Taylor on 12/4/22.
//

import SwiftUI

struct Rule: View {
    enum Orientation {
        case horizontal
        case vertical
    }
    let orientation: Orientation
    
    init(_ orientation: Orientation) {
        self.orientation = orientation
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            Path() { path in
                var origin = CGPoint(x: 0, y: 0)
                var end = CGPoint(x: size.width, y: size.height)
                switch orientation {
                case .horizontal:
                    origin.y = floor(size.height / 2.0 - 1.0)
                    end.x = size.width
                    end.y = floor(size.height / 2.0 - 1.0)
                case .vertical:
                    origin.x = floor(size.width / 2.0 - 1.0)
                    end.x = origin.x
                    end.y = size.height
                }

                path.move(to: origin)
                path.addLine(to: end)
            }
            .strokedPath(StrokeStyle(lineWidth:2.0))
        }
    }
}

struct Rule_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Rule(.vertical)
            Rule(.horizontal)
        }
    }
}
