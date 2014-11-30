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
    println("  operators: Swift language operator head characters")
    println("  letters: NSCharacterSet.letterCharacterSet")
    println("  punctuation: NSCharacterSet.punctuationCharacterSet")
    println("  symbols: NSCharacterSet.symbolCharacterSet")
    println("  sympunct: symbols ∪ punctuation")
}

if Process.arguments.count < 2 {
    usage()
    exit(2)
}

extension UnicodeScalar {
    var intValue: Int { get {return Int(self.value)} }
}

extension NSMutableCharacterSet {
    func addCharacter(i: Int) {
        self.addCharactersInRange(NSMakeRange(i, 1))
    }
    func addCharacter(ch: UnicodeScalar) {
        self.addCharactersInRange(NSMakeRange(ch.intValue, 1))
    }
}

extension NSCharacterSet {
    func unionWithCharacterSet(otherSet: NSCharacterSet) -> NSCharacterSet {
        let set: NSMutableCharacterSet = self.mutableCopy() as NSMutableCharacterSet
        set.formUnionWithCharacterSet(otherSet)
        return set.copy() as NSMutableCharacterSet
    }
}

/// Character set of Swift operator-head characters.
func swiftOperatorHeadCharacterSet() -> NSCharacterSet {
    let cset = NSMutableCharacterSet()
    // operator-head → /  =  -  +  !  *  %  <  >  &  | ^  ~  ?
    cset.addCharactersInString("/=-+!*%<>&|^~?")
    //‌ operator-head → U+00A1–U+00A7
    cset.addCharactersInRange(NSRange(0xA1...0xA7))
    //‌ operator-head → U+00A9 or U+00AB
    cset.addCharacter(0xA9)
    cset.addCharacter(0xAB)
    //‌ operator-head → U+00AC or U+00AE
    cset.addCharacter(0xAC)
    cset.addCharacter(0xAE)
    //‌ operator-head → U+00B0–U+00B1, U+00B6, U+00BB, U+00BF, U+00D7, or U+00F7
    cset.addCharactersInRange(NSRange(0xB0...0xB1))
    cset.addCharacter(0xB6)
    cset.addCharacter(0xBB)
    cset.addCharacter(0xBF)
    cset.addCharacter(0xD7)
    cset.addCharacter(0xF7)
    //‌ operator-head → U+2016–U+2017 or U+2020–U+2027
    cset.addCharactersInRange(NSRange(0x2016...0x2017))
    cset.addCharactersInRange(NSRange(0x2020...0x2027))
    //‌ operator-head → U+2030–U+203E
    cset.addCharactersInRange(NSRange(0x2030...0x203E))
    //‌ operator-head → U+2041–U+2053
    cset.addCharactersInRange(NSRange(0x2041...0x2053))
    //‌ operator-head → U+2055–U+205E
    cset.addCharactersInRange(NSRange(0x2055...0x205E))
    // operator-head → U+2190–U+23FF
    cset.addCharactersInRange(NSRange(0x2190...0x23FF))
    // operator-head → U+2500–U+2775
    cset.addCharactersInRange(NSRange(0x2500...0x2775))
    // operator-head → U+2794–U+2BFF
    cset.addCharactersInRange(NSRange(0x2794...0x2BFF))
    // operator-head → U+2E00–U+2E7F
    cset.addCharactersInRange(NSRange(0x2E00...0x2E7F))
    // operator-head → U+3001–U+3003
    cset.addCharactersInRange(NSRange(0x3001...0x3003))
    // operator-head → U+3008–U+3030
    cset.addCharactersInRange(NSRange(0x3008...0x3030))
    // dot-operator-head → ..
    cset.addCharacter(".")
    return cset.copy() as NSCharacterSet
}

// Pick the character set from the command-line arg.
let charsetName = Process.arguments[1]
let (charset: NSCharacterSet, title: String) = {
    switch (charsetName) {
    case "operators":
        return (swiftOperatorHeadCharacterSet(), "Swift Operator Head")
    case "letters":
        return (NSCharacterSet.letterCharacterSet(), "Letters")
    case "punctuation":
        return (NSCharacterSet.punctuationCharacterSet(), "Punctuation")
    case "symbols":
        return (NSCharacterSet.symbolCharacterSet(), "Symbols")
    case "sympunct":
        return (NSCharacterSet.symbolCharacterSet()
                .unionWithCharacterSet(NSCharacterSet.punctuationCharacterSet()), 
            "Symbols and Punctuation")
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

/// Return the character for a row and column in the table.
func bitChar(base: UInt32, bits: UInt16, column: UInt16) -> UnicodeScalar? {
    let mask = 1 << column
    if mask & bits == 0 {
        return nil
    } else {
        return UnicodeScalar(base+UInt32(column))
    }
}

// Returns HTML entity for characters that need escaping.
func escape(c: UnicodeScalar) -> String {
    switch c {
    case "&": return "&amp;"
    case "<": return "&lt;"
    case ">": return "&gt;"
    default: return String(c)
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
                let s = escape(ch)
                print("<td>\(s)</td>")
            }
            else {
                print("<td></td>")
            }
        }
        //}
        println("</tr>")
    }
}

println("</tbody></table>")
