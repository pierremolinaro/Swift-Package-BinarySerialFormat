//--------------------------------------------------------------------------------------------------
//  Created by Pierre Molinaro on 10/10/2026.
//--------------------------------------------------------------------------------------------------

import Foundation
import Synchronization

//--------------------------------------------------------------------------------------------------

public class BinarySerialFormat <
             SEND_CODE : BinarySendCodeProtocol,
             RECEIVE_CODE : BinaryReceiveCodeProtocol> {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private var mReceiveCallBack : Optional < (_ inCommand : Command <RECEIVE_CODE>) -> Void > = nil
  private var mSendCallBack : Optional < (_ inData : Data) -> Void > = nil
  private let mReceiverManager = Mutex <ReceiverManager <RECEIVE_CODE>> (ReceiverManager ())

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public init () {
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public func setReceiveCallBack (_ inCompletionCallBack : Optional < (_ inCommand : Command <RECEIVE_CODE>) -> Void >) {
    self.mReceiveCallBack = inCompletionCallBack
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public func setSendCallBack (_ inSendCallBack : Optional < (_ inData : Data) -> Void >) {
    self.mSendCallBack = inSendCallBack
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public nonisolated func removeAllReceivedDatas () {
    self.mReceiverManager.withLock { $0 = ReceiverManager () }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private nonisolated func sendData (_ inData : Data) {
    self.mSendCallBack? (inData)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //MARK: Send
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public nonisolated func send (command inCommand : SEND_CODE) {
    var byte = inCommand.rawValue | 0xC0
    let data = unsafe Data (bytes: &byte, count: 1)
    self.sendData (data)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public nonisolated func send (encodedU64 inValue : UInt64) {
    var data = Data ()
    data.append (UInt8 ((inValue & 0x0F) | 0x80))
    var v = inValue >> 4
    while v > 0 {
      data.append (UInt8 (v & 0x7F))
      v >>= 7
    }
    self.sendData (data)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public nonisolated func send (encodedString inValue : String) {
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
    self.sendData (data)
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  //MARK: Receive
  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  nonisolated public func handleReceivedData (_ inData : Data) {
    for byte in inData {
      self.mReceiverManager.withLock { $0.handleReceivedByte (byte) }
    }
    self.mReceiverManager.withLock {
      while !$0.mCommands.isEmpty {
        let command = $0.mCommands.removeFirst ()
        self.mReceiveCallBack? (command)
      }
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------

nonisolated public enum Parameter : Sendable {
  case u64 (UInt64)
  case s64 (Int64)
  case str (String)

  public var u64 : UInt64? {
    switch self {
    case .u64 (let v): return v
    case .s64, .str: return nil
    }
  }

  public var s64 : Int64? {
    switch self {
    case .s64 (let v): return v
    case .u64, .str: return nil
    }
  }

  public var str : String? {
    switch self {
    case .str (let v): return v
    case .u64, .s64: return nil
    }
  }
}

//--------------------------------------------------------------------------------------------------
