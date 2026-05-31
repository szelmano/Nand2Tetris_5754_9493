package scratch

uses java.nio.file.Files
uses java.nio.file.Paths
uses java.nio.charset.StandardCharsets
uses java.util.ArrayList
uses java.lang.StringBuilder

class JackTokenizer {
  var _tokens : List<Token> = new ArrayList<Token>()

  static var KEYWORDS : Set<String> = {
    "class", "constructor", "function", "method", "field", "static",
    "var", "int", "char", "boolean", "void",
    "true", "false", "null", "this",
    "let", "do", "if", "else", "while", "return"
  }

  static var SYMBOLS : Set<String> = {
    "{", "}", "(", ")", "[", "]", ".", ",", ";",
    "+", "-", "*", "/", "&", "|", "<", ">", "=", "~"
  }

  construct(filePath : String) {
    var content = readFile(filePath)
    var cleaned = removeComments(content)
    tokenize(cleaned)
  }

  function allTokens() : List<Token> {
    return _tokens
  }

  function writeTokensXml(outputPath : String) : void {
    var lines = new ArrayList<String>()
    lines.add("<tokens>")
    for (t in _tokens) {
      lines.add(t.toXmlLine())
    }
    lines.add("</tokens>")
    Files.write(Paths.get(outputPath), lines, StandardCharsets.UTF_8)
  }

  private function readFile(filePath : String) : String {
    var bytes = Files.readAllBytes(Paths.get(filePath))
    return new String(bytes, StandardCharsets.UTF_8)
  }

  private function removeComments(input : String) : String {
    var result = new StringBuilder()
    var i = 0
    var inString = false

    while (i < input.length()) {
      var c = input.charAt(i)

      if (c == '"') {
        result.append(c)
        inString = not inString
        i = i + 1
        continue
      }

      if (not inString and c == '/' and i + 1 < input.length()) {
        var next = input.charAt(i + 1)

        if (next == '/') {
          i = i + 2
          while (i < input.length() and input.charAt(i) != '\n') {
            i = i + 1
          }
          continue
        }

        if (next == '*') {
          i = i + 2
          while (i + 1 < input.length() and not (input.charAt(i) == '*' and input.charAt(i + 1) == '/')) {
            i = i + 1
          }
          i = i + 2
          continue
        }
      }

      result.append(c)
      i = i + 1
    }

    return result.toString()
  }

  private function tokenize(input : String) : void {
    var i = 0

    while (i < input.length()) {
      var c = input.charAt(i)

      if (isWhitespace(c)) {
        i = i + 1
        continue
      }

      if (c == '"') {
        var sb = new StringBuilder()
        i = i + 1
        while (i < input.length() and input.charAt(i) != '"') {
          sb.append(input.charAt(i))
          i = i + 1
        }
        _tokens.add(new Token(TokenType.STRING_CONSTANT, sb.toString()))
        i = i + 1
        continue
      }

      if (isSymbolChar(c)) {
        _tokens.add(new Token(TokenType.SYMBOL, charToString(c)))
        i = i + 1
        continue
      }

      if (isDigit(c)) {
        var sbNum = new StringBuilder()
        while (i < input.length() and isDigit(input.charAt(i))) {
          sbNum.append(input.charAt(i))
          i = i + 1
        }
        _tokens.add(new Token(TokenType.INTEGER_CONSTANT, sbNum.toString()))
        continue
      }

      if (isIdentifierStart(c)) {
        var sbWord = new StringBuilder()
        while (i < input.length() and isIdentifierPart(input.charAt(i))) {
          sbWord.append(input.charAt(i))
          i = i + 1
        }

        var word = sbWord.toString()
        if (KEYWORDS.contains(word)) {
          _tokens.add(new Token(TokenType.KEYWORD, word))
        } else {
          _tokens.add(new Token(TokenType.IDENTIFIER, word))
        }
        continue
      }

      i = i + 1
    }
  }

  private function isWhitespace(c : char) : boolean {
    return c == ' ' or c == '\t' or c == '\n' or c == '\r'
  }

  private function isDigit(c : char) : boolean {
    return c >= '0' and c <= '9'
  }

  private function isIdentifierStart(c : char) : boolean {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_'
  }

  private function isIdentifierPart(c : char) : boolean {
    return isIdentifierStart(c) or isDigit(c)
  }

  private function isSymbolChar(c : char) : boolean {
    return SYMBOLS.contains(charToString(c))
  }

  private function charToString(c : char) : String {
    return new StringBuilder().append(c).toString()
  }
}