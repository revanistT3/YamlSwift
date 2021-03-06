import Foundation

func matchRange (string: String, regex: NSRegularExpression) -> NSRange {
  let sr = NSMakeRange(0, string.utf16.count)
  return regex.rangeOfFirstMatchInString(string, options: [], range: sr)
}

func matches (string: String, regex: NSRegularExpression) -> Bool {
  return matchRange(string, regex: regex).location != NSNotFound
}

func regex (pattern: String, options: String = "") -> NSRegularExpression! {
  if matches(options, regex: invalidOptionsPattern) {
    return nil
  }

  let opts = options.characters.reduce(NSRegularExpressionOptions()) { (acc, opt) -> NSRegularExpressionOptions in
    return NSRegularExpressionOptions(rawValue:acc.rawValue | (regexOptions[opt] ?? NSRegularExpressionOptions()).rawValue)
  }
  do {
    return try NSRegularExpression(pattern: pattern, options: opts)
  } catch _ {
    return nil
  }
}

let invalidOptionsPattern =
        try! NSRegularExpression(pattern: "[^ixsm]", options: [])

let regexOptions: [Character: NSRegularExpressionOptions] = [
  "i": .CaseInsensitive,
  "x": .AllowCommentsAndWhitespace,
  "s": .DotMatchesLineSeparators,
  "m": .AnchorsMatchLines
]

extension String {
  func replace (expression: String, with: String) -> String {
    return self
      .componentsSeparatedByString(expression)
      .joinWithSeparator(with)
  }
}

func replace (regex: NSRegularExpression, block: [String] -> String)
    -> String -> String {
      return { string in
        let s = NSMutableString(string: string)
        let range = NSMakeRange(0, string.utf16.count)
        var offset = 0
        regex.enumerateMatchesInString(string, options: [], range: range) {
          result, _, _ in
          if let result = result {
              var captures = [String](count: result.numberOfRanges, repeatedValue: "")
              for i in 0..<result.numberOfRanges {
                if let r = result.rangeAtIndex(i).toRange() {
                  captures[i] = (string as NSString).substringWithRange(NSRange(r))
                }
              }
              let replacement = block(captures)
              let offR = NSMakeRange(result.range.location + offset, result.range.length)
              offset += replacement.characters.count - result.range.length
              s.replaceCharactersInRange(offR, withString: replacement)
          }
        }
        return s as String
      }
}

func splitLead (regex: NSRegularExpression) -> String
    -> (String, String) {
      return { string in
        let r = matchRange(string, regex: regex)
        if r.location == NSNotFound {
          return ("", string)
        } else {
          let s = string
          let i = string.startIndex.advancedBy(r.location + r.length)
          return (s.substringToIndex(i), s.substringFromIndex(i))
        }
      }
}

func splitTrail (regex: NSRegularExpression) -> String
    -> (String, String) {
      return { string in
        let r = matchRange(string, regex: regex)
        if r.location == NSNotFound {
          return (string, "")
        } else {
          let s = string as NSString
          let i = r.location
          return (s.substringToIndex(i), s.substringFromIndex(i))
        }
      }
}

extension String {
  subscript(toIndex index:String.Index) -> String {
    return self[self.startIndex...index]
  }
  subscript(fromIndex index:String.Index) -> String {
    return self[index...self.endIndex.predecessor()]
  }
}
