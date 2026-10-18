//--------------------------------------------------------------------------------------------------
//  Created by Pierre Molinaro on 10/10/2026.
//--------------------------------------------------------------------------------------------------

import Foundation
import Synchronization

//--------------------------------------------------------------------------------------------------

public nonisolated struct BinarySerialFormat <SEND_CODE : BinarySendCodeProtocol,
                                  RECEIVE_CODE : BinaryReceiveCodeProtocol> {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public init () {
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public nonisolated mutating func removeAllReceivedDatas () {
    self.mReceiverManager = ReceiverManager <RECEIVE_CODE> ()
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //MARK: Send
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public nonisolated func data (forCommand inCommand : SEND_CODE) -> Data {
    var byte = inCommand.rawValue | 0xC0
    let data = unsafe Data (bytes: &byte, count: 1)
    return data
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public nonisolated func data (forEncodedU64 inValue : UInt64) -> Data {
    var data = Data ()
    data.append (UInt8 ((inValue & 0x0F) | 0x80))
    var v = inValue >> 4
    while v > 0 {
      data.append (UInt8 (v & 0x7F))
      v >>= 7
    }
    return data
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public nonisolated func data (forEncodedString inValue : String) -> Data {
    var data = Data ()
    data.append (0xA0)
    for utf32 in inValue.unicodeScalars {
      let pointCode : UInt32 = utf32.value
      if (pointCode >= 0x10) && (pointCode <= 0x1F) { // control 0001 xxxx
        data.append (UInt8 (pointCode))
        data.append (0x41) ;
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
  //MARK: Receive
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private var mReceiverManager = ReceiverManager <RECEIVE_CODE> ()

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  nonisolated public mutating func handleReceivedData (_ inData : Data,
                                                       _ outCommands : inout [Command <RECEIVE_CODE>]) {
    outCommands.removeAll ()
    for byte in inData {
      self.mReceiverManager.handleReceivedByte (byte, &outCommands)
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
