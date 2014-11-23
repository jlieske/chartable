//
//  main.swift
//  CharTable
//
//  Created by Jay Lieske on 2014.11.14.
//  Copyright (c) 2014 Jay Lieske. All rights reserved.
//

import Foundation

func usage() {
    println("chartable [character set name] >table.md")
    println("Generates a Markdown file with a table listing the characters")
    println("that in the named character set.")
    println("Allowed values for character set name:")
    println("  letters (default): NSCharacterSet.letterCharacterSet")
    println("  punctuation: NSCharacterSet.punctuationCharacterSet")
    println("  symbols: NSCharacterSet.symbolCharacterSet")
}

if Process.arguments.count < 2 {
    usage()
    exit(2)
}

let charsetName = Process.arguments[1]
let (charset: NSCharacterSet, title: String) = {
    switch (charsetName) {
    case "letters":
        return (NSCharacterSet.letterCharacterSet(), "Letters")
    case "punctuation":
        return (NSCharacterSet.punctuationCharacterSet(), "Punctuation")
    case "symbols":
        return (NSCharacterSet.symbolCharacterSet(), "Symbols")
    case let name:
        println("Unknown character set name: \(name)")
        usage()
        exit(3)
    }
}()
let charsetBits = charset.bitmapRepresentation

/// Extension for NSData to treat bytes as integers.
extension NSData {
    /// Treat the data as an array of UInt16 values, and return the index'th one.
    func uint16AtIndex(index: Int) -> UInt16 {
        var word: UInt16 = 0
        self.getBytes(&word, range: NSMakeRange(index*2, sizeofValue(word)))
        return word
    }
    /// Treat the data as an array of 16-bit values, and return the count.
    var count16: Int { get {
        return self.length / 2 // round down, ignore incomplete values at end
    } }
}

func bitChar(base: UInt32, bits: UInt16, column: UInt16) -> UnicodeScalar? {
    let mask = 1 << column
    if mask & bits == 0 {
        return nil
    } else {
        return UnicodeScalar(base+UInt32(column))
    }
}

// Generate Markdown header.

println("# \(title)")

// Generate HTML table with characters.

println("<table><thead><tr><th></th>")
println("<th>0</th><th>1</th><th>2</th><th>3</th>")
println("<th>4</th><th>5</th><th>6</th><th>7</th>")
println("<th>8</th><th>9</th><th>A</th><th>B</th>")
println("<th>C</th><th>D</th><th>E</th><th>F</th>")
println("</tr></thead><tbody>")

for i in 0..<charsetBits.count16 {
    let bits = charsetBits.uint16AtIndex(i)
    if bits != 0 {
        let row = UInt32(i) * 16
        let hex = String(format: "%X", row)
        println("<tr><th>\(hex)</th>")
        //autoreleasepool {
        for col: UInt16 in 0...15 {
            if let ch = bitChar(row, bits, col) {
                print("<th>\(ch)</th>") // TODO: escape character
            }
            else {
                print("<th></th>")
            }
        }
        //}
        println("</tr>")
    }
}

println("</tbody></table>")
