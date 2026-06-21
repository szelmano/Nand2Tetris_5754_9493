package scratch

class SymbolInfo {
  var _type : String
  var _kind : SymbolKind
  var _index : int

  construct(type : String, kind : SymbolKind, index : int) {
    _type = type
    _kind = kind
    _index = index
  }

  property get Type() : String {
    return _type
  }

  property get Kind() : SymbolKind {
    return _kind
  }

  property get Index() : int {
    return _index
  }
}