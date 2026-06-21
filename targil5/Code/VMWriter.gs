package scratch

uses java.io.BufferedWriter
uses java.io.FileWriter
uses java.io.IOException

class VMWriter {
  var _writer : BufferedWriter

  construct(outputPath : String) {
    _writer = new BufferedWriter(new FileWriter(outputPath))
  }

  function writePush(segment : String, index : int) : void {
    writeLine("push " + segment + " " + index)
  }

  function writePop(segment : String, index : int) : void {
    writeLine("pop " + segment + " " + index)
  }

  function writeArithmetic(command : String) : void {
    writeLine(command)
  }

  function writeLabel(label : String) : void {
    writeLine("label " + label)
  }

  function writeGoto(label : String) : void {
    writeLine("goto " + label)
  }

  function writeIf(label : String) : void {
    writeLine("if-goto " + label)
  }

  function writeCall(name : String, numberOfArguments : int) : void {
    writeLine("call " + name + " " + numberOfArguments)
  }

  function writeFunction(name : String, numberOfLocals : int) : void {
    writeLine("function " + name + " " + numberOfLocals)
  }

  function writeReturn() : void {
    writeLine("return")
  }

  function close() : void {
    if (_writer != null) {
      _writer.close()
    }
  }

  private function writeLine(line : String) : void {
    _writer.write(line)
    _writer.newLine()
  }
}