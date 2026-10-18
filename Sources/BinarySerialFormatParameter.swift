//--------------------------------------------------------------------------------------------------
//  Created by Pierre Molinaro on 18/10/2026.
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
