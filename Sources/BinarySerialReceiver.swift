//--------------------------------------------------------------------------------------------------
//  Created by Pierre Molinaro on 10/10/2026.
//--------------------------------------------------------------------------------------------------

import Foundation
import Synchronization

//--------------------------------------------------------------------------------------------------

public struct BinarySerialReceiver <RECEIVE_CODE : BinaryReceiveCodeProtocol> : Sendable {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private var mReceiverManager = ReceiverManager <RECEIVE_CODE> ()

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public init () {
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public mutating func removeAllReceivedDatas () {
    self.mReceiverManager = ReceiverManager <RECEIVE_CODE> ()
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  public mutating func handleReceivedData (_ inData : Data,
                                           _ outCommands : inout [BinarySerialCommand <RECEIVE_CODE>]) {
    outCommands.removeAll ()
    for byte in inData {
      self.mReceiverManager.handleReceivedByte (byte, &outCommands)
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
