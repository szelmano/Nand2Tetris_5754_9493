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

  var _symbolTable : SymbolTable
  var _className : String

  var _vmWriter : VMWriter
  var _currentSubroutineName : String
  var _currentSubroutineKind : String

  var _ifCounter : int = 0
  var _whileCounter : int = 0

  construct(tokens : List<Token>) {
    _tokens = tokens
    _symbolTable = new SymbolTable()
  }

  function writeXml(outputPath : String) : void {
    resetCompilationState()
    _vmWriter = null

    compileClass()

    Files.write(
      Paths.get(outputPath),
      _lines,
      StandardCharsets.UTF_8
    )
  }

  function writeVm(outputPath : String) : void {
    resetCompilationState()

    _vmWriter = new VMWriter(outputPath)

    try {
      compileClass()
    } finally {
      _vmWriter.close()
      _vmWriter = null
    }
  }

  private function resetCompilationState() : void {
    _index = 0
    _lines.clear()
    _indent = 0

    _symbolTable = new SymbolTable()

    _className = null
    _currentSubroutineName = null
    _currentSubroutineKind = null

    _ifCounter = 0
    _whileCounter = 0
  }

  private function compileClass() : void {
    openTag("class")

    writeCurrentAndAdvance()

    _className = currentValue()
    writeCurrentAndAdvance()

    writeCurrentAndAdvance()

    while (isClassVarDec()) {
      compileClassVarDec()
    }

    while (isSubroutineDec()) {
      compileSubroutine()
    }

    writeCurrentAndAdvance()

    closeTag("class")
  }

  private function compileClassVarDec() : void {
    openTag("classVarDec")

    var kindText = currentValue()
    var kind : SymbolKind

    if (kindText == "static") {
      kind = SymbolKind.STATIC
    } else {
      kind = SymbolKind.FIELD
    }

    writeCurrentAndAdvance()

    var type = currentValue()
    writeCurrentAndAdvance()

    var name = currentValue()
    _symbolTable.define(name, type, kind)
    writeCurrentAndAdvance()

    while (currentValue() == ",") {
      writeCurrentAndAdvance()

      name = currentValue()
      _symbolTable.define(name, type, kind)
      writeCurrentAndAdvance()
    }

    writeCurrentAndAdvance()

    closeTag("classVarDec")
  }

  private function compileSubroutine() : void {
    openTag("subroutineDec")

    _symbolTable.startSubroutine()

    _currentSubroutineKind = currentValue()
    writeCurrentAndAdvance()

    if (_currentSubroutineKind == "method") {
      _symbolTable.define(
        "this",
        _className,
        SymbolKind.ARG
      )
    }

    writeCurrentAndAdvance()

    _currentSubroutineName = currentValue()
    writeCurrentAndAdvance()

    writeCurrentAndAdvance()

    compileParameterList()

    writeCurrentAndAdvance()

    compileSubroutineBody()

    closeTag("subroutineDec")
  }

  private function compileParameterList() : void {
    openTag("parameterList")

    if (currentValue() != ")") {
      var type = currentValue()
      writeCurrentAndAdvance()

      var name = currentValue()

      _symbolTable.define(
        name,
        type,
        SymbolKind.ARG
      )

      writeCurrentAndAdvance()

      while (currentValue() == ",") {
        writeCurrentAndAdvance()

        type = currentValue()
        writeCurrentAndAdvance()

        name = currentValue()

        _symbolTable.define(
          name,
          type,
          SymbolKind.ARG
        )

        writeCurrentAndAdvance()
      }
    }

    closeTag("parameterList")
  }

  private function compileSubroutineBody() : void {
    openTag("subroutineBody")

    writeCurrentAndAdvance()

    while (currentValue() == "var") {
      compileVarDec()
    }

    if (_vmWriter != null) {
      var fullFunctionName =
        _className + "." + _currentSubroutineName

      var numberOfLocals =
        _symbolTable.varCount(SymbolKind.VAR)

      _vmWriter.writeFunction(
        fullFunctionName,
        numberOfLocals
      )

      if (_currentSubroutineKind == "method") {
        _vmWriter.writePush("argument", 0)
        _vmWriter.writePop("pointer", 0)
      }

      if (_currentSubroutineKind == "constructor") {
        var numberOfFields =
          _symbolTable.varCount(SymbolKind.FIELD)

        _vmWriter.writePush(
          "constant",
          numberOfFields
        )

        _vmWriter.writeCall(
          "Memory.alloc",
          1
        )

        _vmWriter.writePop(
          "pointer",
          0
        )
      }
    }

    compileStatements()

    writeCurrentAndAdvance()

    closeTag("subroutineBody")
  }

  private function compileVarDec() : void {
    openTag("varDec")

    writeCurrentAndAdvance()

    var type = currentValue()
    writeCurrentAndAdvance()

    var name = currentValue()

    _symbolTable.define(
      name,
      type,
      SymbolKind.VAR
    )

    writeCurrentAndAdvance()

    while (currentValue() == ",") {
      writeCurrentAndAdvance()

      name = currentValue()

      _symbolTable.define(
        name,
        type,
        SymbolKind.VAR
      )

      writeCurrentAndAdvance()
    }

    writeCurrentAndAdvance()

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

    writeCurrentAndAdvance()

    var variableName = currentValue()
    writeCurrentAndAdvance()

    var isArrayAssignment = false

    if (currentValue() == "[") {
      isArrayAssignment = true

      writeCurrentAndAdvance()

      if (_vmWriter != null) {
        pushVariable(variableName)
      }

      compileExpression()

      if (_vmWriter != null) {
        _vmWriter.writeArithmetic("add")
      }

      writeCurrentAndAdvance()
    }

    writeCurrentAndAdvance()

    compileExpression()

    if (_vmWriter != null) {
      if (isArrayAssignment) {

        _vmWriter.writePop("temp", 0)
        _vmWriter.writePop("pointer", 1)
        _vmWriter.writePush("temp", 0)
        _vmWriter.writePop("that", 0)

      } else {
        popVariable(variableName)
      }
    }

    writeCurrentAndAdvance()

    closeTag("letStatement")
  }

  private function compileIf() : void {
    openTag("ifStatement")

    var currentIfNumber = _ifCounter
    _ifCounter = _ifCounter + 1

    var trueLabel =
      "IF_TRUE" + currentIfNumber

    var falseLabel =
      "IF_FALSE" + currentIfNumber

    var endLabel =
      "IF_END" + currentIfNumber

    writeCurrentAndAdvance()
    writeCurrentAndAdvance()

    compileExpression()

    writeCurrentAndAdvance()

    if (_vmWriter != null) {

      _vmWriter.writeIf(trueLabel)
      _vmWriter.writeGoto(falseLabel)
      _vmWriter.writeLabel(trueLabel)
    }

    writeCurrentAndAdvance()

    compileStatements()

    writeCurrentAndAdvance()

    if (currentValue() == "else") {
      if (_vmWriter != null) {
        _vmWriter.writeGoto(endLabel)
        _vmWriter.writeLabel(falseLabel)
      }

      writeCurrentAndAdvance()
      writeCurrentAndAdvance()

      compileStatements()

      writeCurrentAndAdvance()

      if (_vmWriter != null) {
        _vmWriter.writeLabel(endLabel)
      }

    } else {
      if (_vmWriter != null) {
        _vmWriter.writeLabel(falseLabel)
      }
    }

    closeTag("ifStatement")
  }

  private function compileWhile() : void {
    openTag("whileStatement")

    var currentWhileNumber = _whileCounter
    _whileCounter = _whileCounter + 1

    var expressionLabel =
      "WHILE_EXP" + currentWhileNumber

    var endLabel =
      "WHILE_END" + currentWhileNumber

    if (_vmWriter != null) {
      _vmWriter.writeLabel(expressionLabel)
    }

    writeCurrentAndAdvance()
    writeCurrentAndAdvance()

    compileExpression()

    writeCurrentAndAdvance()

    if (_vmWriter != null) {

      _vmWriter.writeArithmetic("not")
      _vmWriter.writeIf(endLabel)
    }

    writeCurrentAndAdvance()

    compileStatements()

    writeCurrentAndAdvance()

    if (_vmWriter != null) {
      _vmWriter.writeGoto(expressionLabel)
      _vmWriter.writeLabel(endLabel)
    }

    closeTag("whileStatement")
  }

  private function compileDo() : void {
    openTag("doStatement")

    writeCurrentAndAdvance()

    compileSubroutineCall()

    if (_vmWriter != null) {

      _vmWriter.writePop("temp", 0)
    }

    writeCurrentAndAdvance()

    closeTag("doStatement")
  }

  private function compileReturn() : void {
    openTag("returnStatement")

    writeCurrentAndAdvance()

    if (currentValue() != ";") {
      compileExpression()

    } else if (_vmWriter != null) {

      _vmWriter.writePush("constant", 0)
    }

    writeCurrentAndAdvance()

    if (_vmWriter != null) {
      _vmWriter.writeReturn()
    }

    closeTag("returnStatement")
  }

  private function compileExpression() : void {
    openTag("expression")

    compileTerm()

    while (isOp(currentValue())) {
      var op = currentValue()

      writeCurrentAndAdvance()

      compileTerm()

      if (_vmWriter != null) {
        writeBinaryOperator(op)
      }
    }

    closeTag("expression")
  }

  private function compileTerm() : void {
    openTag("term")

    var token = currentToken()
    var value = token.Value

    if (token.Type == TokenType.INTEGER_CONSTANT) {
      if (_vmWriter != null) {
        _vmWriter.writePush(
          "constant",
          Integer.parseInt(value)
        )
      }

      writeCurrentAndAdvance()

    } else if (token.Type == TokenType.STRING_CONSTANT) {
      if (_vmWriter != null) {
        writeStringConstant(value)
      }

      writeCurrentAndAdvance()

    } else if (
      token.Type == TokenType.KEYWORD and
      isKeywordConstant(value)
    ) {
      if (_vmWriter != null) {
        writeKeywordConstant(value)
      }

      writeCurrentAndAdvance()

    } else if (value == "(") {
      writeCurrentAndAdvance()

      compileExpression()

      writeCurrentAndAdvance()

    } else if (value == "-" or value == "~") {
      var unaryOperator = value

      writeCurrentAndAdvance()

      compileTerm()

      if (_vmWriter != null) {
        if (unaryOperator == "-") {
          _vmWriter.writeArithmetic("neg")
        } else {
          _vmWriter.writeArithmetic("not")
        }
      }

    } else {
      var name = value
      var next = peekValue()

      if (next == "[") {
        writeCurrentAndAdvance()
        writeCurrentAndAdvance()

        if (_vmWriter != null) {
          pushVariable(name)
        }

        compileExpression()

        if (_vmWriter != null) {
          _vmWriter.writeArithmetic("add")
          _vmWriter.writePop("pointer", 1)
          _vmWriter.writePush("that", 0)
        }

        writeCurrentAndAdvance()

      } else if (next == "(" or next == ".") {
        compileSubroutineCall()

      } else {
        if (_vmWriter != null) {
          pushVariable(name)
        }

        writeCurrentAndAdvance()
      }
    }

    closeTag("term")
  }

  private function compileExpressionList() : int {
    openTag("expressionList")

    var numberOfExpressions = 0

    if (currentValue() != ")") {
      compileExpression()
      numberOfExpressions = numberOfExpressions + 1

      while (currentValue() == ",") {
        writeCurrentAndAdvance()

        compileExpression()

        numberOfExpressions =
          numberOfExpressions + 1
      }
    }

    closeTag("expressionList")

    return numberOfExpressions
  }

  private function compileSubroutineCall() : void {
    var firstName = currentValue()

    writeCurrentAndAdvance()

    var fullName : String
    var numberOfArguments = 0

    if (currentValue() == ".") {
      writeCurrentAndAdvance()

      var subroutineName = currentValue()
      writeCurrentAndAdvance()

      if (
        _symbolTable.kindOf(firstName) !=
        SymbolKind.NONE
      ) {
        if (_vmWriter != null) {
          pushVariable(firstName)
        }

        numberOfArguments = 1

        fullName =
          _symbolTable.typeOf(firstName) +
          "." +
          subroutineName

      } else {
        fullName =
          firstName +
          "." +
          subroutineName
      }

    } else {
      fullName =
        _className +
        "." +
        firstName

      if (_vmWriter != null) {
        _vmWriter.writePush("pointer", 0)
      }

      numberOfArguments = 1
    }

    writeCurrentAndAdvance()

    numberOfArguments =
      numberOfArguments +
      compileExpressionList()

    writeCurrentAndAdvance()

    if (_vmWriter != null) {
      _vmWriter.writeCall(
        fullName,
        numberOfArguments
      )
    }
  }

  private function writeBinaryOperator(
    op : String
  ) : void {

    if (op == "+") {
      _vmWriter.writeArithmetic("add")

    } else if (op == "-") {
      _vmWriter.writeArithmetic("sub")

    } else if (op == "*") {
      _vmWriter.writeCall("Math.multiply", 2)

    } else if (op == "/") {
      _vmWriter.writeCall("Math.divide", 2)

    } else if (op == "&") {
      _vmWriter.writeArithmetic("and")

    } else if (op == "|") {
      _vmWriter.writeArithmetic("or")

    } else if (op == "<") {
      _vmWriter.writeArithmetic("lt")

    } else if (op == ">") {
      _vmWriter.writeArithmetic("gt")

    } else if (op == "=") {
      _vmWriter.writeArithmetic("eq")
    }
  }

  private function writeKeywordConstant(
    value : String
  ) : void {

    if (value == "false" or value == "null") {
      _vmWriter.writePush("constant", 0)

    } else if (value == "true") {
      _vmWriter.writePush("constant", 0)
      _vmWriter.writeArithmetic("not")

    } else if (value == "this") {
      _vmWriter.writePush("pointer", 0)
    }
  }

  private function writeStringConstant(
    value : String
  ) : void {

    _vmWriter.writePush(
      "constant",
      value.length()
    )

    _vmWriter.writeCall(
      "String.new",
      1
    )

    var i = 0

    while (i < value.length()) {
      _vmWriter.writePush(
        "constant",
        value.charAt(i) as int
      )

      _vmWriter.writeCall(
        "String.appendChar",
        2
      )

      i = i + 1
    }
  }

  private function pushVariable(
    name : String
  ) : void {

    var kind = _symbolTable.kindOf(name)
    var index = _symbolTable.indexOf(name)
    var segment = segmentOf(kind)

    if (segment == null) {
      throw new IllegalArgumentException(
        "Unknown variable: " + name
      )
    }

    _vmWriter.writePush(segment, index)
  }

  private function popVariable(
    name : String
  ) : void {

    var kind = _symbolTable.kindOf(name)
    var index = _symbolTable.indexOf(name)
    var segment = segmentOf(kind)

    if (segment == null) {
      throw new IllegalArgumentException(
        "Unknown variable: " + name
      )
    }

    _vmWriter.writePop(segment, index)
  }

  private function segmentOf(
    kind : SymbolKind
  ) : String {

    if (kind == SymbolKind.STATIC) {
      return "static"
    }

    if (kind == SymbolKind.FIELD) {
      return "this"
    }

    if (kind == SymbolKind.ARG) {
      return "argument"
    }

    if (kind == SymbolKind.VAR) {
      return "local"
    }

    return null
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
    var result = ""
    var i = 0

    while (i < _indent) {
      result = result + "  "
      i = i + 1
    }

    return result
  }

  private function isClassVarDec() : boolean {
    return currentValue() == "static" or
           currentValue() == "field"
  }

  private function isSubroutineDec() : boolean {
    return currentValue() == "constructor" or
           currentValue() == "function" or
           currentValue() == "method"
  }

  private function isStatement() : boolean {
    return currentValue() == "let" or
           currentValue() == "if" or
           currentValue() == "while" or
           currentValue() == "do" or
           currentValue() == "return"
  }

  private function isOp(value : String) : boolean {
    return value == "+" or
           value == "-" or
           value == "*" or
           value == "/" or
           value == "&" or
           value == "|" or
           value == "<" or
           value == ">" or
           value == "="
  }

  private function isKeywordConstant(
    value : String
  ) : boolean {

    return value == "true" or
           value == "false" or
           value == "null" or
           value == "this"
  }
}
