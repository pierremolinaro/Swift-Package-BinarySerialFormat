//--------------------------------------------------------------------------------------------------
//  Created by Pierre Molinaro on 18/10/2026.
//--------------------------------------------------------------------------------------------------

import Testing
@testable import BinarySerialFormat

//--------------------------------------------------------------------------------------------------
// ⌘U exécute tous les tests.
// cliquer sur le losange situé à côté d'une méthode de test ou d'une classe de tests pour
// ne lancer que ceux-ci.
//
//--------------------------------------------------------------------------------------------------

enum SendCommand : UInt8, BinarySendCodeProtocol {
  case test = 0x00
}

//--------------------------------------------------------------------------------------------------

enum ReceiveCommand : UInt8, BinaryReceiveCodeProtocol {
  case test = 0x00
}

//--------------------------------------------------------------------------------------------------

@Test func testEncodageDécodageF32 () {
  var bsf = BinarySerialReceiver <ReceiveCommand> ()
  for v : UInt32 in 0 ... UInt32.max {
//    let v = UInt32.random (in: 0 ... UInt32.max)
    // print ("v: " + String (v, radix: 16))
    let f = Float (bitPattern: v)
    var data = BinarySerialFormatter.data (forF32: f)
    data += BinarySerialFormatter.data (forCommand: SendCommand.test)
//    var s = "DATA"
//    for byte in data {
//      s += " " + String (byte, radix: 16)
//    }
//    print (s)
    bsf.removeAllReceivedDatas ()
    var commands = [BinarySerialCommand <ReceiveCommand>] ()
    bsf.handleReceivedData (data, &commands)
    #expect (commands.count == 1)
    #expect (commands [0].parameters.count == 1)
    #expect (commands [0].parameters [0].f32 != nil)
//    print (commands [0].parameters [0].f32!.bitPattern, v)
    #expect (commands [0].parameters [0].f32!.bitPattern == v)
  }
}

//--------------------------------------------------------------------------------------------------
