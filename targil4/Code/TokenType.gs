package scratch

enum TokenType {
  KEYWORD,
  SYMBOL,
  IDENTIFIER,
  INTEGER_CONSTANT,
  STRING_CONSTANT

  function xmlTag() : String {
    switch (this) {
      case KEYWORD:
        return "keyword"
      case SYMBOL:
        return "symbol"
      case IDENTIFIER:
        return "identifier"
      case INTEGER_CONSTANT:
        return "integerConstant"
      case STRING_CONSTANT:
        return "stringConstant"
      default:
        return ""
    }
  }
}