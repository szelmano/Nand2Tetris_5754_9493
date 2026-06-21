package scratch

class Token {
  var _type : TokenType
  var _value : String

  construct(type : TokenType, value : String) {
    _type = type
    _value = value
  }

  property get Type() : TokenType {
    return _type
  }

  property get Value() : String {
    return _value
  }

  function toXmlLine() : String {
    return "<" + _type.xmlTag() + "> " + escapeXml(_value) + " </" + _type.xmlTag() + ">"
  }

  private function escapeXml(text : String) : String {
    if (text == "<") {
      return "&lt;"
    }
    if (text == ">") {
      return "&gt;"
    }
    if (text == "&") {
      return "&amp;"
    }
    if (text == "\"") {
      return "&quot;"
    }
    return text
  }

  override function toString() : String {
    return _type + ": " + _value
  }
}