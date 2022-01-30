//
//  Formatter+Extensions.swift
//  HEX
//
//  Created by Joe Blau on 1/29/22.
//

import Foundation

extension Formatter {
    static var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.negativePrefix = " $"
        f.positivePrefix = " $"
        return f
    }
    
    static var dayTimeDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }
    
    static var hourTimeDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }
    
    static var minuteTimeDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }
}
