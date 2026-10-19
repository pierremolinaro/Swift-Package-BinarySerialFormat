//--------------------------------------------------------------------------------------------------
//  Created by Pierre Molinaro on 19/10/2026.
//--------------------------------------------------------------------------------------------------

import Foundation

//--------------------------------------------------------------------------------------------------

public extension String {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  var binarySerialData : Data {
    var data = Data ()
    data.append (0xA0)
    for utf32 in self.unicodeScalars {
      let pointCode : UInt32 = utf32.value
      if (pointCode >= 0x10) && (pointCode <= 0x1F) { // control 0001 xxxx
        data.append (UInt8 (pointCode))
        data.append (0x41)
      }else if pointCode <= 0x7F { // ASCII
        data.append (UInt8 (pointCode))
      }else if pointCode <= 0x3FF {
        data.append (UInt8 (pointCode & 0x0F) | 0x10)
        data.append (UInt8 (pointCode >> 4) | 0x40)
      }else if pointCode <= 0xFFFF {
        data.append (UInt8 (pointCode & 0x0F) | 0x10)
        data.append (UInt8 (pointCode >> 4) & 0x3F)
        data.append (UInt8 (pointCode >> 10) | 0x40)
      }else{
        data.append (UInt8 (pointCode & 0x0F) | 0x10)
        data.append (UInt8 (pointCode >> 4) & 0x3F)
        data.append (UInt8 (pointCode >> 10) & 0x3F)
        data.append (UInt8 (pointCode >> 16) | 0x40)
      }
    }
    return data
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
