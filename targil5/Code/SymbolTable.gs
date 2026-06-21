package scratch

uses java.util.HashMap
uses java.util.Map

class SymbolTable {
  var _classScope : Map<String, SymbolInfo>
  var _subroutineScope : Map<String, SymbolInfo>

  var _staticCount : int
  var _fieldCount : int
  var _argCount : int
  var _varCount : int

  construct() {
    _classScope = new HashMap<String, SymbolInfo>()
    _subroutineScope = new HashMap<String, SymbolInfo>()

    _staticCount = 0
    _fieldCount = 0
    _argCount = 0
    _varCount = 0
  }

  function startSubroutine() : void {
    _subroutineScope.clear()
    _argCount = 0
    _varCount = 0
  }

  function define(name : String, type : String, kind : SymbolKind) : void {
    var index = varCount(kind)
    var symbol = new SymbolInfo(type, kind, index)

    if (kind == SymbolKind.STATIC) {
      _classScope.put(name, symbol)
      _staticCount++
    } else if (kind == SymbolKind.FIELD) {
      _classScope.put(name, symbol)
      _fieldCount++
    } else if (kind == SymbolKind.ARG) {
      _subroutineScope.put(name, symbol)
      _argCount++
    } else if (kind == SymbolKind.VAR) {
      _subroutineScope.put(name, symbol)
      _varCount++
    }
  }

  function varCount(kind : SymbolKind) : int {
    if (kind == SymbolKind.STATIC) {
      return _staticCount
    }

    if (kind == SymbolKind.FIELD) {
      return _fieldCount
    }

    if (kind == SymbolKind.ARG) {
      return _argCount
    }

    if (kind == SymbolKind.VAR) {
      return _varCount
    }

    return 0
  }

  function kindOf(name : String) : SymbolKind {
    var symbol = findSymbol(name)

    if (symbol == null) {
      return SymbolKind.NONE
    }

    return symbol.Kind
  }

  function typeOf(name : String) : String {
    var symbol = findSymbol(name)

    if (symbol == null) {
      return null
    }

    return symbol.Type
  }

  function indexOf(name : String) : int {
    var symbol = findSymbol(name)

    if (symbol == null) {
      return -1
    }

    return symbol.Index
  }

  private function findSymbol(name : String) : SymbolInfo {
    if (_subroutineScope.containsKey(name)) {
      return _subroutineScope.get(name)
    }

    if (_classScope.containsKey(name)) {
      return _classScope.get(name)
    }

    return null
  }
}