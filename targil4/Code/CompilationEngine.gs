package scratch

uses java.nio.file.Files
uses java.nio.file.Paths
uses java.nio.charset.StandardCharsets
uses java.util.ArrayList

class CompilationEngine {
  var _tokens : List<Token>
  var _index : int = 0
  var _lines : List<String> = new ArrayList<String>()
  var _indent : int = 0

  construct(tokens : List<Token>) {
    _tokens = tokens
  }

  function writeXml(outputPath : String) : void {
    compileClass()
    Files.write(Paths.get(outputPath), _lines, StandardCharsets.UTF_8)
  }

  private function compileClass() : void {
    openTag("class")

    writeCurrentAndAdvance() // class
    writeCurrentAndAdvance() // className
    writeCurrentAndAdvance() // {

    while (isClassVarDec()) {
      compileClassVarDec()
    }

    while (isSubroutineDec()) {
      compileSubroutine()
    }

    writeCurrentAndAdvance() // }

    closeTag("class")
  }

  private function compileClassVarDec() : void {
    openTag("classVarDec")

    writeCurrentAndAdvance() // static | field
    writeCurrentAndAdvance() // type
    writeCurrentAndAdvance() // varName

    while (currentValue() == ",") {
      writeCurrentAndAdvance() // ,
      writeCurrentAndAdvance() // varName
    }

    writeCurrentAndAdvance() // ;

    closeTag("classVarDec")
  }

  private function compileSubroutine() : void {
    openTag("subroutineDec")

    writeCurrentAndAdvance() // constructor | function | method
    writeCurrentAndAdvance() // void | type
    writeCurrentAndAdvance() // subroutineName
    writeCurrentAndAdvance() // (
    compileParameterList()
    writeCurrentAndAdvance() // )
    compileSubroutineBody()

    closeTag("subroutineDec")
  }

  private function compileParameterList() : void {
    openTag("parameterList")

    if (currentValue() != ")") {
      writeCurrentAndAdvance() // type
      writeCurrentAndAdvance() // varName

      while (currentValue() == ",") {
        writeCurrentAndAdvance() // ,
        writeCurrentAndAdvance() // type
        writeCurrentAndAdvance() // varName
      }
    }

    closeTag("parameterList")
  }

  private function compileSubroutineBody() : void {
    openTag("subroutineBody")

    writeCurrentAndAdvance() // {

    while (currentValue() == "var") {
      compileVarDec()
    }

    compileStatements()

    writeCurrentAndAdvance() // }

    closeTag("subroutineBody")
  }

  private function compileVarDec() : void {
    openTag("varDec")

    writeCurrentAndAdvance() // var
    writeCurrentAndAdvance() // type
    writeCurrentAndAdvance() // varName

    while (currentValue() == ",") {
      writeCurrentAndAdvance() // ,
      writeCurrentAndAdvance() // varName
    }

    writeCurrentAndAdvance() // ;

    closeTag("varDec")
  }

  private function compileStatements() : void {
    openTag("statements")

    while (isStatement()) {
      if (currentValue() == "let") {
        compileLet()
      } else if (currentValue() == "if") {
        compileIf()
      } else if (currentValue() == "while") {
        compileWhile()
      } else if (currentValue() == "do") {
        compileDo()
      } else if (currentValue() == "return") {
        compileReturn()
      }
    }

    closeTag("statements")
  }

  private function compileLet() : void {
    openTag("letStatement")

    writeCurrentAndAdvance() // let
    writeCurrentAndAdvance() // varName

    if (currentValue() == "[") {
      writeCurrentAndAdvance() // [
      compileExpression()
      writeCurrentAndAdvance() // ]
    }

    writeCurrentAndAdvance() // =
    compileExpression()
    writeCurrentAndAdvance() // ;

    closeTag("letStatement")
  }

  private function compileIf() : void {
    openTag("ifStatement")

    writeCurrentAndAdvance() // if
    writeCurrentAndAdvance() // (
    compileExpression()
    writeCurrentAndAdvance() // )
    writeCurrentAndAdvance() // {
    compileStatements()
    writeCurrentAndAdvance() // }

    if (currentValue() == "else") {
      writeCurrentAndAdvance() // else
      writeCurrentAndAdvance() // {
      compileStatements()
      writeCurrentAndAdvance() // }
    }

    closeTag("ifStatement")
  }

  private function compileWhile() : void {
    openTag("whileStatement")

    writeCurrentAndAdvance() // while
    writeCurrentAndAdvance() // (
    compileExpression()
    writeCurrentAndAdvance() // )
    writeCurrentAndAdvance() // {
    compileStatements()
    writeCurrentAndAdvance() // }

    closeTag("whileStatement")
  }

  private function compileDo() : void {
    openTag("doStatement")

    writeCurrentAndAdvance() // do
    compileSubroutineCall()
    writeCurrentAndAdvance() // ;

    closeTag("doStatement")
  }

  private function compileReturn() : void {
    openTag("returnStatement")

    writeCurrentAndAdvance() // return

    if (currentValue() != ";") {
      compileExpression()
    }

    writeCurrentAndAdvance() // ;

    closeTag("returnStatement")
  }

  private function compileExpression() : void {
    openTag("expression")

    compileTerm()

    while (isOp(currentValue())) {
      writeCurrentAndAdvance() // op
      compileTerm()
    }

    closeTag("expression")
  }

  private function compileTerm() : void {
    openTag("term")

    var token = currentToken()
    var value = token.Value

    if (token.Type == TokenType.INTEGER_CONSTANT or
        token.Type == TokenType.STRING_CONSTANT or
        token.Type == TokenType.KEYWORD and isKeywordConstant(value)) {
      writeCurrentAndAdvance()
    } else if (value == "(") {
      writeCurrentAndAdvance() // (
      compileExpression()
      writeCurrentAndAdvance() // )
    } else if (value == "-" or value == "~") {
      writeCurrentAndAdvance() // unaryOp
      compileTerm()
    } else {
      var next = peekValue()

      if (next == "[") {
        writeCurrentAndAdvance() // varName
        writeCurrentAndAdvance() // [
        compileExpression()
        writeCurrentAndAdvance() // ]
      } else if (next == "(" or next == ".") {
        compileSubroutineCall()
      } else {
        writeCurrentAndAdvance() // varName
      }
    }

    closeTag("term")
  }

  private function compileExpressionList() : void {
    openTag("expressionList")

    if (currentValue() != ")") {
      compileExpression()

      while (currentValue() == ",") {
        writeCurrentAndAdvance() // ,
        compileExpression()
      }
    }

    closeTag("expressionList")
  }

  private function compileSubroutineCall() : void {
    writeCurrentAndAdvance() // subroutineName | className | varName

    if (currentValue() == ".") {
      writeCurrentAndAdvance() // .
      writeCurrentAndAdvance() // subroutineName
    }

    writeCurrentAndAdvance() // (
    compileExpressionList()
    writeCurrentAndAdvance() // )
  }

  private function currentToken() : Token {
    return _tokens[_index]
  }

  private function currentValue() : String {
    if (_index >= _tokens.Count) {
      return ""
    }
    return _tokens[_index].Value
  }

  private function peekValue() : String {
    if (_index + 1 >= _tokens.Count) {
      return ""
    }
    return _tokens[_index + 1].Value
  }

  private function writeCurrentAndAdvance() : void {
    writeLine(currentToken().toXmlLine())
    _index = _index + 1
  }

  private function openTag(tag : String) : void {
    writeLine("<" + tag + ">")
    _indent = _indent + 1
  }

  private function closeTag(tag : String) : void {
    _indent = _indent - 1
    writeLine("</" + tag + ">")
  }

  private function writeLine(text : String) : void {
    _lines.add(indentSpaces() + text)
  }

  private function indentSpaces() : String {
    var s = ""
    var i = 0
    while (i < _indent) {
      s = s + "  "
      i = i + 1
    }
    return s
  }

  private function isClassVarDec() : boolean {
    return currentValue() == "static" or currentValue() == "field"
  }

  private function isSubroutineDec() : boolean {
    return currentValue() == "constructor" or currentValue() == "function" or currentValue() == "method"
  }

  private function isStatement() : boolean {
    return currentValue() == "let" or
           currentValue() == "if" or
           currentValue() == "while" or
           currentValue() == "do" or
           currentValue() == "return"
  }

  private function isOp(value : String) : boolean {
    return value == "+" or value == "-" or value == "*" or value == "/" or
           value == "&" or value == "|" or value == "<" or value == ">" or value == "="
  }

  private function isKeywordConstant(value : String) : boolean {
    return value == "true" or value == "false" or value == "null" or value == "this"
  }
}