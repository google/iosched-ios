//
//  Copyright (c) 2017 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

/// Extension that provides specific colors for use with the application.
extension UIColor {

  // swiftlint:disable variable_name

  // MARK: - Init

  /**
   Convenience initialiser for creating UIColor objects with RGB values ranging from 0-255.

   - parameter r: Int representing the red component of the color ranging from 0 to 255.
   - parameter g: Int representing the green component of the color ranging from 0 to 255.
   - parameter b: Int representing the blue component of the color ranging from 0 to 255.

   - returns: UIColor representing the RGB values with alpha set to full 1.
   */
  convenience init(r: Int, g: Int, b: Int) {
    self.init(r: r, g: g, b: b, a: 1)
  }

  /**
   Convenience initializer for creating UIColor objects with RGB values ranging from 0-255 and alpha
   ranging from 0-1.

   - parameter r: Int representing the red component of the color ranging from 0 to 255.
   - parameter g: Int representing the green component of the color ranging from 0 to 255.
   - parameter b: Int representing the blue component of the color ranging from 0 to 255.
   - parameter a: Int representing the alpha component of the color ranging from 0 to 1.

   - returns: UIColor object representing the given RGBA values.
   */
  convenience init(r: Int, g: Int, b: Int, a: CGFloat) {
    assert(r >= 0 && r <= 255, "Invalid red component")
    assert(g >= 0 && g <= 255, "Invalid green component")
    assert(b >= 0 && b <= 255, "Invalid blue component")
    assert(a >= 0 && a <= 1, "Invalid alpha component")

    let red = CGFloat(r) / 255.0
    let green = CGFloat(g) / 255.0
    let blue = CGFloat(b) / 255.0

    self.init(red: red, green: green, blue: blue, alpha: a)
  }

  /**
   Convenience initialiser for creating UIColor objects with a hex number representation
   (e.g. 0x4285F4 or 0x4285F450). If no alpha component given it defaults to 0xFF.

   - parameter hex: Int representing the red, green and blue components of the color.

   - returns: UIColor representing the hex value provided.
   */
  convenience init(hex: Int) {
    var bytesToShift = 8 * 2
    let alphaExists = hex > 0xffffff

    // If there's an alpha component to shift.
    if alphaExists {
      bytesToShift += 8
    }

    let red = (hex >> bytesToShift) & 0xff
    bytesToShift -= 8
    let green = (hex >> bytesToShift) & 0xff
    bytesToShift -= 8
    let blue = (hex >> bytesToShift) & 0xff
    let alpha: CGFloat
    if alphaExists {
      let alphaInt = hex & 0xff
      alpha = CGFloat(alphaInt) / 255.0
    } else {
      alpha = 1
    }

    self.init(r: red, g: green, b: blue, a: alpha)
  }

  /**
   Convenience initializer for creating UIColor objects with a hex string with the #RRGGBB or
   #RRGGBBAA format (e.g. #4285F4 or #4285F450).

   - parameter hexString: Seven or nine character string containing a # and followed only hex
   characters.

   - returns: UIColor if successfully parsed, otherwise nil.
   */
  convenience init?(hexString: String) {

    var hex = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()

    let numCharacters = hex.count

    guard hex.hasPrefix("#") && (numCharacters == 7 || numCharacters == 9) else {
      return nil
    }

    // Remove # prefix.
    hex = String(hex[hex.index(hex.startIndex, offsetBy: 1)...])

    let rString = hex[..<hex.index(hex.startIndex, offsetBy: 2)]

    let substringFrom2 = hex[hex.index(hex.startIndex, offsetBy: 2)...]
    let gString = substringFrom2[..<substringFrom2.index(substringFrom2.startIndex, offsetBy: 2)]

    let substringFrom4 = hex[hex.index(hex.startIndex, offsetBy: 4)...]
    let bString = substringFrom4[..<substringFrom4.index(substringFrom4.startIndex, offsetBy: 2)]
    var r: CUnsignedInt = 0, g: CUnsignedInt = 0, b: CUnsignedInt = 0

    Scanner(string: String(rString)).scanHexInt32(&r)
    Scanner(string: String(gString)).scanHexInt32(&g)
    Scanner(string: String(bString)).scanHexInt32(&b)

    if numCharacters == 9 {
      let substringFrom6 = hex[hex.index(hex.startIndex, offsetBy: 6)...]
      let aString = substringFrom6[..<substringFrom6.index(substringFrom6.startIndex, offsetBy: 2)]
      var a: CUnsignedInt = 0
      Scanner(string: String(aString)).scanHexInt32(&a)
      self.init(r: Int(r), g: Int(g), b: Int(b), a: CGFloat(a) / 255.0)
    } else {
      self.init(r: Int(r), g: Int(g), b: Int(b))
    }
  }

  // swiftlint:enable variable_name
}
