//--------------------------------------------------------------------------------------------------
//  Created by Pierre Molinaro on 18/10/2026.
//--------------------------------------------------------------------------------------------------

import Foundation

//--------------------------------------------------------------------------------------------------

nonisolated struct ReceiverManager <RECEIVE_CODE : BinaryReceiveCodeProtocol> {

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  var mDecoderState = DecoderState.idle
  var mDecodingU64Value : UInt64 = 0
  var mDecodingU64Shift : Int = 0
  var mDecodingString = Data ()
  var mParameterStack = [BinarySerialParameter] ()

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private enum ByteFormat {
    case parameterExtension
    case beginF32
    case beginUnsigned
    case beginNegative
    case beginString
    case command
    case undefined
  } ;

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private nonisolated static func formatForByte (_ inByte : UInt8) -> ByteFormat {
    var result = ByteFormat.undefined
    if (inByte & 0x80) == 0 {
      result = .parameterExtension
    }else if (inByte & 0xF0) == 0x80 {
      result = .beginUnsigned
    }else if (inByte & 0xF0) == 0x90 {
      result = .beginNegative
    }else if inByte == 0xA0 {
      result = .beginString
    }else if (inByte & 0xF0) == 0xB0 {
      result = .beginF32
    }else if (inByte & 0xC0) == 0xC0 {
      result = .command
    }
    return result
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  enum DecoderState {
    case idle
    case decodingF32
    case decodingUnsigned
    case decodingNegative
    case decodingString
    case error
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private func decodeStringFromByteArray () -> String {
    var utf32Array = [UnicodeScalar] ()
    var multiByteShift : UInt32 = 0
    var utf32Value : UInt32 = 0
    for byte in self.mDecodingString {
      if multiByteShift > 0 {
        if (byte & 0x40) == 0 {
          utf32Value |= UInt32 (byte & 0x3F) << multiByteShift
          multiByteShift += 6
        }else{ // End of multi byte
          utf32Value |= UInt32 (byte & 0x3F) << multiByteShift
          utf32Array.append (UnicodeScalar (utf32Value)!)
          utf32Value = 0 ;
          multiByteShift = 0 ;
        }
      }else if byte >= 0x10, byte <= 0x1F { // Start multibyte
        utf32Value = UInt32 (byte & 0x0F)
        multiByteShift = 4
      }else{
        utf32Array.append (UnicodeScalar (byte))
      }
    }
    return String (String.UnicodeScalarView (utf32Array))
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  private mutating func closeCurrentValueDecoding () {
    switch self.mDecoderState {
    case .decodingF32 :
      // print ("REVD " + String (self.mDecodingU64Value, radix: 16))
      self.mParameterStack.append (.f32 (Float (bitPattern: UInt32 (self.mDecodingU64Value))))
      self.mDecoderState = .idle
    case .decodingUnsigned :
      self.mParameterStack.append (.u64 (self.mDecodingU64Value))
      self.mDecoderState = .idle
    case .decodingNegative :
      let v = Int64 (bitPattern: ~self.mDecodingU64Value)
      self.mParameterStack.append (.s64 (v))
      self.mDecoderState = .idle
    case .decodingString :
      let s = self.decodeStringFromByteArray ()
      self.mParameterStack.append (.str (s))
      self.mDecoderState = .idle
    case .idle :
      ()
    case .error :
      ()
    }
  }

  // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  mutating func handleReceivedByte (_ inByte : UInt8,
                                    _ outCommands : inout [BinarySerialCommand <RECEIVE_CODE>]) {
    let f : ByteFormat = Self.formatForByte (inByte)
    switch f {
    case .parameterExtension :
      switch self.mDecoderState {
      case .decodingF32 :
        if self.mDecodingU64Shift >= 0 {
          self.mDecodingU64Value |= UInt64 (inByte & 0x7F) << self.mDecodingU64Shift
          self.mDecodingU64Shift -= 7
        }
      case .decodingUnsigned :
        self.mDecodingU64Value |= UInt64 (inByte & 0x7F) << self.mDecodingU64Shift
        self.mDecodingU64Shift += 7
      case .decodingNegative :
        self.mDecodingU64Value |= UInt64 (inByte & 0x7F) << self.mDecodingU64Shift
        self.mDecodingU64Shift += 7
      case .decodingString :
        self.mDecodingString.append (inByte)
      case .idle :
        ()
      case .error :
        ()
      }
    case .beginF32 :
      self.closeCurrentValueDecoding ()
      self.mDecodingU64Value = UInt64 (inByte & 0x0F) << 28
      self.mDecodingU64Shift = 21
      self.mDecoderState = .decodingF32
    case .beginUnsigned :
      self.closeCurrentValueDecoding ()
      self.mDecodingU64Value = UInt64 (inByte & 0x0F)
      self.mDecodingU64Shift = 4
      self.mDecoderState = .decodingUnsigned
    case .beginNegative :
      self.closeCurrentValueDecoding () ;
      self.mDecodingU64Value = UInt64 (inByte & 0x0F)
      self.mDecodingU64Shift = 4
      self.mDecoderState = .decodingNegative
    case .beginString :
      self.closeCurrentValueDecoding ()
      self.mDecodingString.removeAll ()
      self.mDecoderState = .decodingString
    case .command :
      self.closeCurrentValueDecoding ()
      if let receiveCode = RECEIVE_CODE (rawValue: inByte & 0x3F) {
        let command = BinarySerialCommand (code: receiveCode, parameters: self.mParameterStack)
        outCommands.append (command)
      }
      self.mParameterStack.removeAll ()
    case .undefined :
      ()
    }
  }

 // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

}

//--------------------------------------------------------------------------------------------------
