uses java.io.File
uses java.io.BufferedWriter
uses java.io.FileWriter
uses java.util.Scanner
uses java.util.HashMap
uses java.util.HashSet
uses java.util.Arrays
uses javax.swing.JOptionPane

var labelCounter : int = 0
var currentFunctionName : String = ""
var callCounter : int = 0

var inputPath = JOptionPane.showInputDialog("Enter folder path:")

if(inputPath == null) {
  print("No input path was provided")
  return
}

inputPath = inputPath.trim()

if(inputPath.length() == 0) {
  print("No input path was provided")
  return
}

// Remove surrounding quotes if the user pasted the path with quotes
if(inputPath.startsWith("\"") and inputPath.endsWith("\"")) {
  inputPath = inputPath.substring(1, inputPath.length() - 1)
}

var inputFolder = new File(inputPath)

if(not inputFolder.exists() or not inputFolder.isDirectory()) {
  print("Folder path not found: " + inputPath)
  return
}

// Create one ASM output file named after the folder
var outputFile = new File(inputFolder, inputFolder.Name + ".asm")
var writer = new BufferedWriter(new FileWriter(outputFile))

try {
  var files = inputFolder.listFiles()

  if(files == null) {
    print("No files found in folder")
    return
  }

  Arrays.sort(files)

  var vmFileCount : int = 0

  for(f in files) {
    if(f.isFile() and f.Name.toLowerCase().endsWith(".vm")) {
      vmFileCount = vmFileCount + 1
      ProcessVmFile(f, writer)
    }
  }

  if(vmFileCount == 0) {
    print("No VM files found directly inside the folder")
  } else {
    print("Translation completed: " + outputFile.AbsolutePath)
  }

} finally {
  writer.close()
}

// --------------------------------------------------
// Helpers
// --------------------------------------------------

function W(outputWriter : BufferedWriter, text : String) {
  outputWriter.write(text + "\n")
}

function CleanLine(line : String) : String {
  var clean = line
  var commentIndex = clean.indexOf("//")

  if(commentIndex >= 0) {
    clean = clean.substring(0, commentIndex)
  }

  return clean.trim()
}

// --------------------------------------------------
// Main file processor
// --------------------------------------------------

function ProcessVmFile(currentInputFile : File, outputWriter : BufferedWriter) {
  var scanner = new Scanner(currentInputFile)

  var segmentMap = new HashMap<String, String>()
  segmentMap.put("local", "LCL")
  segmentMap.put("argument", "ARG")
  segmentMap.put("this", "THIS")
  segmentMap.put("that", "THAT")

  var arithmeticSet = new HashSet<String>()
  arithmeticSet.add("add")
  arithmeticSet.add("sub")
  arithmeticSet.add("neg")
  arithmeticSet.add("and")
  arithmeticSet.add("or")
  arithmeticSet.add("not")
  arithmeticSet.add("eq")
  arithmeticSet.add("lt")
  arithmeticSet.add("gt")

  try {
    while(scanner.hasNextLine()) {
      var rawLine = scanner.nextLine()
      var line = CleanLine(rawLine)

      if(line.length() == 0) {
        continue
      }

      var parts = line.split(" ")

      if(parts[0] == "push") {
      HandlePush(parts, currentInputFile, segmentMap, outputWriter)

    } else if(parts[0] == "pop") {
      HandlePop(parts, currentInputFile, segmentMap, outputWriter)

    } else if(parts[0] == "label") {
      WriteLabel(parts[1], outputWriter)

    } else if(parts[0] == "goto") {
      WriteGoto(parts[1], outputWriter)

    } else if(parts[0] == "if-goto") {
      WriteIf(parts[1], outputWriter)

    } else if(parts[0] == "function") {
      WriteFunction(parts[1], parts[2], outputWriter)

    } else if(parts[0] == "call") {
      WriteCall(parts[1], parts[2], outputWriter)

    } else if(parts[0] == "return") {
     WriteReturn(outputWriter)

    } else if(arithmeticSet.contains(line)) {
      WriteArithmetic(line, outputWriter)
    }
    }
  } finally {
    scanner.close()
  }
}

// --------------------------------------------------
// Dispatch
// --------------------------------------------------

function HandlePush(parts : String[], currentInputFile : File, segmentMap : HashMap<String, String>, outputWriter : BufferedWriter) {
  var segment = parts[1]
  var index = parts[2]

  if(segment == "constant") {
    WritePushConstant(index, outputWriter)

  } else if(segmentMap.containsKey(segment)) {
    WritePushFromSegment(segmentMap.get(segment), index, outputWriter)

  } else if(segment == "temp") {
    WritePushTemp(index, outputWriter)

  } else if(segment == "pointer") {
    WritePushPointer(index, outputWriter)

  } else if(segment == "static") {
    WritePushStatic(index, currentInputFile, outputWriter)
  }
}

function HandlePop(parts : String[], currentInputFile : File, segmentMap : HashMap<String, String>, outputWriter : BufferedWriter) {
  var segment = parts[1]
  var index = parts[2]

  if(segmentMap.containsKey(segment)) {
    WritePopToSegment(segmentMap.get(segment), index, outputWriter)

  } else if(segment == "temp") {
    WritePopTemp(index, outputWriter)

  } else if(segment == "pointer") {
    WritePopPointer(index, outputWriter)

  } else if(segment == "static") {
    WritePopStatic(index, currentInputFile, outputWriter)
  }
}

// --------------------------------------------------
// Push / Pop writers
// --------------------------------------------------

function WritePushConstant(value : String, outputWriter : BufferedWriter) {
  W(outputWriter, "// push constant " + value)
  W(outputWriter, "@" + value)
  W(outputWriter, "D=A")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")
}

function WritePushFromSegment(segmentBase : String, index : String, outputWriter : BufferedWriter) {
  W(outputWriter, "// push " + segmentBase + " " + index)
  W(outputWriter, "@" + segmentBase)
  W(outputWriter, "D=M")
  W(outputWriter, "@" + index)
  W(outputWriter, "A=D+A")
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")
}

function WritePopToSegment(segmentBase : String, index : String, outputWriter : BufferedWriter) {
  W(outputWriter, "// pop " + segmentBase + " " + index)
  W(outputWriter, "@" + segmentBase)
  W(outputWriter, "D=M")
  W(outputWriter, "@" + index)
  W(outputWriter, "D=D+A")
  W(outputWriter, "@R13")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@R13")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
}

function WritePushTemp(index : String, outputWriter : BufferedWriter) {
  W(outputWriter, "// push temp " + index)
  W(outputWriter, "@5")
  W(outputWriter, "D=A")
  W(outputWriter, "@" + index)
  W(outputWriter, "A=D+A")
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")
}

function WritePopTemp(index : String, outputWriter : BufferedWriter) {
  W(outputWriter, "// pop temp " + index)
  W(outputWriter, "@5")
  W(outputWriter, "D=A")
  W(outputWriter, "@" + index)
  W(outputWriter, "D=D+A")
  W(outputWriter, "@R13")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@R13")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
}

function WritePushPointer(index : String, outputWriter : BufferedWriter) {
  var base = ""

  if(index == "0") {
    base = "THIS"
  } else {
    base = "THAT"
  }

  W(outputWriter, "// push pointer " + index)
  W(outputWriter, "@" + base)
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")
}

function WritePopPointer(index : String, outputWriter : BufferedWriter) {
  var base = ""

  if(index == "0") {
    base = "THIS"
  } else {
    base = "THAT"
  }

  W(outputWriter, "// pop pointer " + index)
  W(outputWriter, "@SP")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@" + base)
  W(outputWriter, "M=D")
}

function WritePushStatic(index : String, currentInputFile : File, outputWriter : BufferedWriter) {
  var fileName = currentInputFile.Name.substring(0, currentInputFile.Name.length() - 3)
  var staticName = fileName + "." + index

  W(outputWriter, "// push static " + index)
  W(outputWriter, "@" + staticName)
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")
}

function WritePopStatic(index : String, currentInputFile : File, outputWriter : BufferedWriter) {
  var fileName = currentInputFile.Name.substring(0, currentInputFile.Name.length() - 3)
  var staticName = fileName + "." + index

  W(outputWriter, "// pop static " + index)
  W(outputWriter, "@SP")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@" + staticName)
  W(outputWriter, "M=D")
}

// --------------------------------------------------
// Arithmetic / Logic
// --------------------------------------------------

function WriteArithmetic(command : String, outputWriter : BufferedWriter) {
  if(command == "add") {
    W(outputWriter, "// add")
    W(outputWriter, "@SP")
    W(outputWriter, "AM=M-1")
    W(outputWriter, "D=M")
    W(outputWriter, "A=A-1")
    W(outputWriter, "M=M+D")

  } else if(command == "sub") {
    W(outputWriter, "// sub")
    W(outputWriter, "@SP")
    W(outputWriter, "AM=M-1")
    W(outputWriter, "D=M")
    W(outputWriter, "A=A-1")
    W(outputWriter, "M=M-D")

  } else if(command == "neg") {
    W(outputWriter, "// neg")
    W(outputWriter, "@SP")
    W(outputWriter, "A=M-1")
    W(outputWriter, "M=-M")

  } else if(command == "and") {
    W(outputWriter, "// and")
    W(outputWriter, "@SP")
    W(outputWriter, "AM=M-1")
    W(outputWriter, "D=M")
    W(outputWriter, "A=A-1")
    W(outputWriter, "M=M&D")

  } else if(command == "or") {
    W(outputWriter, "// or")
    W(outputWriter, "@SP")
    W(outputWriter, "AM=M-1")
    W(outputWriter, "D=M")
    W(outputWriter, "A=A-1")
    W(outputWriter, "M=M|D")

  } else if(command == "not") {
    W(outputWriter, "// not")
    W(outputWriter, "@SP")
    W(outputWriter, "A=M-1")
    W(outputWriter, "M=!M")

  } else if(command == "eq") {
    WriteComparison("JEQ", "EQ", outputWriter)

  } else if(command == "lt") {
    WriteComparison("JLT", "LT", outputWriter)

  } else if(command == "gt") {
    WriteComparison("JGT", "GT", outputWriter)
  }
}

function WriteComparison(jumpCommand : String, prefix : String, outputWriter : BufferedWriter) {
  var trueLabel = "TRUE_" + prefix + "_" + labelCounter
  var endLabel = "END_" + prefix + "_" + labelCounter
  labelCounter = labelCounter + 1

  W(outputWriter, "// " + prefix.toLowerCase())
  W(outputWriter, "@SP")
  W(outputWriter, "A=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "A=A-1")
  W(outputWriter, "D=M-D")
  W(outputWriter, "@" + trueLabel)
  W(outputWriter, "D;" + jumpCommand)
  W(outputWriter, "@SP")
  W(outputWriter, "A=M-1")
  W(outputWriter, "A=A-1")
  W(outputWriter, "M=0")
  W(outputWriter, "@" + endLabel)
  W(outputWriter, "0;JMP")
  W(outputWriter, "(" + trueLabel + ")")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M-1")
  W(outputWriter, "A=A-1")
  W(outputWriter, "M=-1")
  W(outputWriter, "(" + endLabel + ")")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M-1")
}

function FullLabelName(labelName : String) : String {
  if(currentFunctionName != null and currentFunctionName.length() > 0) {
    return currentFunctionName + "$" + labelName
  }
  return labelName
}

function WriteLabel(labelName : String, outputWriter : BufferedWriter) {
  var fullLabel = FullLabelName(labelName)
  W(outputWriter, "// label " + labelName)
  W(outputWriter, "(" + fullLabel + ")")
}

function WriteGoto(labelName : String, outputWriter : BufferedWriter) {
  var fullLabel = FullLabelName(labelName)
  W(outputWriter, "// goto " + labelName)
  W(outputWriter, "@" + fullLabel)
  W(outputWriter, "0;JMP")
}

function WriteIf(labelName : String, outputWriter : BufferedWriter) {
  var fullLabel = FullLabelName(labelName)
  W(outputWriter, "// if-goto " + labelName)
  W(outputWriter, "@SP")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@" + fullLabel)
  W(outputWriter, "D;JNE")
}

function WriteFunction(functionName : String, numLocalsText : String, outputWriter : BufferedWriter) {
  currentFunctionName = functionName
  var numLocals = Integer.parseInt(numLocalsText)

  W(outputWriter, "// function " + functionName + " " + numLocalsText)
  W(outputWriter, "(" + functionName + ")")

  for(i in 0..|numLocals) {
    WritePushConstant("0", outputWriter)
  }
}

function WriteCall(functionName : String, numArgsText : String, outputWriter : BufferedWriter) {
  var returnLabel = "RETURN_" + functionName + "_" + callCounter
  callCounter = callCounter + 1
  var numArgs = Integer.parseInt(numArgsText)

  W(outputWriter, "// call " + functionName + " " + numArgsText)

  // push return address
  W(outputWriter, "@" + returnLabel)
  W(outputWriter, "D=A")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")

  // push LCL
  W(outputWriter, "@LCL")
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")

  // push ARG
  W(outputWriter, "@ARG")
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")

  // push THIS
  W(outputWriter, "@THIS")
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")

  // push THAT
  W(outputWriter, "@THAT")
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")

  // ARG = SP - 5 - nArgs
  W(outputWriter, "@SP")
  W(outputWriter, "D=M")
  W(outputWriter, "@5")
  W(outputWriter, "D=D-A")
  W(outputWriter, "@" + numArgs)
  W(outputWriter, "D=D-A")
  W(outputWriter, "@ARG")
  W(outputWriter, "M=D")

  // LCL = SP
  W(outputWriter, "@SP")
  W(outputWriter, "D=M")
  W(outputWriter, "@LCL")
  W(outputWriter, "M=D")

  // goto function
  W(outputWriter, "@" + functionName)
  W(outputWriter, "0;JMP")

  // return label
  W(outputWriter, "(" + returnLabel + ")")
}

function WriteReturn(outputWriter : BufferedWriter) {
  W(outputWriter, "// return")

  // frame = LCL
  W(outputWriter, "@LCL")
  W(outputWriter, "D=M")
  W(outputWriter, "@R13")
  W(outputWriter, "M=D")

  // ret = *(frame - 5)
  W(outputWriter, "@5")
  W(outputWriter, "A=D-A")
  W(outputWriter, "D=M")
  W(outputWriter, "@R14")
  W(outputWriter, "M=D")

  // *ARG = pop()
  W(outputWriter, "@SP")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@ARG")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")

  // SP = ARG + 1
  W(outputWriter, "@ARG")
  W(outputWriter, "D=M+1")
  W(outputWriter, "@SP")
  W(outputWriter, "M=D")

  // THAT = *(frame - 1)
  W(outputWriter, "@R13")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@THAT")
  W(outputWriter, "M=D")

  // THIS = *(frame - 2)
  W(outputWriter, "@R13")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@THIS")
  W(outputWriter, "M=D")

  // ARG = *(frame - 3)
  W(outputWriter, "@R13")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@ARG")
  W(outputWriter, "M=D")

  // LCL = *(frame - 4)
  W(outputWriter, "@R13")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@LCL")
  W(outputWriter, "M=D")

  // goto ret
  W(outputWriter, "@R14")
  W(outputWriter, "A=M")
  W(outputWriter, "0;JMP")
}uses java.io.File
uses java.io.BufferedWriter
uses java.io.FileWriter
uses java.util.Scanner
uses java.util.HashMap
uses java.util.HashSet
uses java.util.Arrays
uses javax.swing.JOptionPane

var labelCounter : int = 0
var currentFunctionName : String = ""
var callCounter : int = 0

var inputPath = JOptionPane.showInputDialog("Enter folder path:")

if(inputPath == null) {
  print("No input path was provided")
  return
}

inputPath = inputPath.trim()

if(inputPath.length() == 0) {
  print("No input path was provided")
  return
}

// Remove surrounding quotes if the user pasted the path with quotes
if(inputPath.startsWith("\"") and inputPath.endsWith("\"")) {
  inputPath = inputPath.substring(1, inputPath.length() - 1)
}

var inputFolder = new File(inputPath)

if(not inputFolder.exists() or not inputFolder.isDirectory()) {
  print("Folder path not found: " + inputPath)
  return
}

// Create one ASM output file named after the folder
var outputFile = new File(inputFolder, inputFolder.Name + ".asm")
var writer = new BufferedWriter(new FileWriter(outputFile))

try {
  var files = inputFolder.listFiles()

  if(files == null) {
    print("No files found in folder")
    return
  }

  Arrays.sort(files)

  var vmFileCount : int = 0

  for(f in files) {
    if(f.isFile() and f.Name.toLowerCase().endsWith(".vm")) {
      vmFileCount = vmFileCount + 1
      ProcessVmFile(f, writer)
    }
  }

  if(vmFileCount == 0) {
    print("No VM files found directly inside the folder")
  } else {
    print("Translation completed: " + outputFile.AbsolutePath)
  }

} finally {
  writer.close()
}

// --------------------------------------------------
// Helpers
// --------------------------------------------------

function W(outputWriter : BufferedWriter, text : String) {
  outputWriter.write(text + "\n")
}

function CleanLine(line : String) : String {
  var clean = line
  var commentIndex = clean.indexOf("//")

  if(commentIndex >= 0) {
    clean = clean.substring(0, commentIndex)
  }

  return clean.trim()
}

// --------------------------------------------------
// Main file processor
// --------------------------------------------------

function ProcessVmFile(currentInputFile : File, outputWriter : BufferedWriter) {
  var scanner = new Scanner(currentInputFile)

  var segmentMap = new HashMap<String, String>()
  segmentMap.put("local", "LCL")
  segmentMap.put("argument", "ARG")
  segmentMap.put("this", "THIS")
  segmentMap.put("that", "THAT")

  var arithmeticSet = new HashSet<String>()
  arithmeticSet.add("add")
  arithmeticSet.add("sub")
  arithmeticSet.add("neg")
  arithmeticSet.add("and")
  arithmeticSet.add("or")
  arithmeticSet.add("not")
  arithmeticSet.add("eq")
  arithmeticSet.add("lt")
  arithmeticSet.add("gt")

  try {
    while(scanner.hasNextLine()) {
      var rawLine = scanner.nextLine()
      var line = CleanLine(rawLine)

      if(line.length() == 0) {
        continue
      }

      var parts = line.split(" ")

      if(parts[0] == "push") {
      HandlePush(parts, currentInputFile, segmentMap, outputWriter)

    } else if(parts[0] == "pop") {
      HandlePop(parts, currentInputFile, segmentMap, outputWriter)

    } else if(parts[0] == "label") {
      WriteLabel(parts[1], outputWriter)

    } else if(parts[0] == "goto") {
      WriteGoto(parts[1], outputWriter)

    } else if(parts[0] == "if-goto") {
      WriteIf(parts[1], outputWriter)

    } else if(parts[0] == "function") {
      WriteFunction(parts[1], parts[2], outputWriter)

    } else if(parts[0] == "call") {
      WriteCall(parts[1], parts[2], outputWriter)

    } else if(parts[0] == "return") {
     WriteReturn(outputWriter)

    } else if(arithmeticSet.contains(line)) {
      WriteArithmetic(line, outputWriter)
    }
    }
  } finally {
    scanner.close()
  }
}

// --------------------------------------------------
// Dispatch
// --------------------------------------------------

function HandlePush(parts : String[], currentInputFile : File, segmentMap : HashMap<String, String>, outputWriter : BufferedWriter) {
  var segment = parts[1]
  var index = parts[2]

  if(segment == "constant") {
    WritePushConstant(index, outputWriter)

  } else if(segmentMap.containsKey(segment)) {
    WritePushFromSegment(segmentMap.get(segment), index, outputWriter)

  } else if(segment == "temp") {
    WritePushTemp(index, outputWriter)

  } else if(segment == "pointer") {
    WritePushPointer(index, outputWriter)

  } else if(segment == "static") {
    WritePushStatic(index, currentInputFile, outputWriter)
  }
}

function HandlePop(parts : String[], currentInputFile : File, segmentMap : HashMap<String, String>, outputWriter : BufferedWriter) {
  var segment = parts[1]
  var index = parts[2]

  if(segmentMap.containsKey(segment)) {
    WritePopToSegment(segmentMap.get(segment), index, outputWriter)

  } else if(segment == "temp") {
    WritePopTemp(index, outputWriter)

  } else if(segment == "pointer") {
    WritePopPointer(index, outputWriter)

  } else if(segment == "static") {
    WritePopStatic(index, currentInputFile, outputWriter)
  }
}

// --------------------------------------------------
// Push / Pop writers
// --------------------------------------------------

function WritePushConstant(value : String, outputWriter : BufferedWriter) {
  W(outputWriter, "// push constant " + value)
  W(outputWriter, "@" + value)
  W(outputWriter, "D=A")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")
}

function WritePushFromSegment(segmentBase : String, index : String, outputWriter : BufferedWriter) {
  W(outputWriter, "// push " + segmentBase + " " + index)
  W(outputWriter, "@" + segmentBase)
  W(outputWriter, "D=M")
  W(outputWriter, "@" + index)
  W(outputWriter, "A=D+A")
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")
}

function WritePopToSegment(segmentBase : String, index : String, outputWriter : BufferedWriter) {
  W(outputWriter, "// pop " + segmentBase + " " + index)
  W(outputWriter, "@" + segmentBase)
  W(outputWriter, "D=M")
  W(outputWriter, "@" + index)
  W(outputWriter, "D=D+A")
  W(outputWriter, "@R13")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@R13")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
}

function WritePushTemp(index : String, outputWriter : BufferedWriter) {
  W(outputWriter, "// push temp " + index)
  W(outputWriter, "@5")
  W(outputWriter, "D=A")
  W(outputWriter, "@" + index)
  W(outputWriter, "A=D+A")
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")
}

function WritePopTemp(index : String, outputWriter : BufferedWriter) {
  W(outputWriter, "// pop temp " + index)
  W(outputWriter, "@5")
  W(outputWriter, "D=A")
  W(outputWriter, "@" + index)
  W(outputWriter, "D=D+A")
  W(outputWriter, "@R13")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@R13")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
}

function WritePushPointer(index : String, outputWriter : BufferedWriter) {
  var base = ""

  if(index == "0") {
    base = "THIS"
  } else {
    base = "THAT"
  }

  W(outputWriter, "// push pointer " + index)
  W(outputWriter, "@" + base)
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")
}

function WritePopPointer(index : String, outputWriter : BufferedWriter) {
  var base = ""

  if(index == "0") {
    base = "THIS"
  } else {
    base = "THAT"
  }

  W(outputWriter, "// pop pointer " + index)
  W(outputWriter, "@SP")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@" + base)
  W(outputWriter, "M=D")
}

function WritePushStatic(index : String, currentInputFile : File, outputWriter : BufferedWriter) {
  var fileName = currentInputFile.Name.substring(0, currentInputFile.Name.length() - 3)
  var staticName = fileName + "." + index

  W(outputWriter, "// push static " + index)
  W(outputWriter, "@" + staticName)
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")
}

function WritePopStatic(index : String, currentInputFile : File, outputWriter : BufferedWriter) {
  var fileName = currentInputFile.Name.substring(0, currentInputFile.Name.length() - 3)
  var staticName = fileName + "." + index

  W(outputWriter, "// pop static " + index)
  W(outputWriter, "@SP")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@" + staticName)
  W(outputWriter, "M=D")
}

// --------------------------------------------------
// Arithmetic / Logic
// --------------------------------------------------

function WriteArithmetic(command : String, outputWriter : BufferedWriter) {
  if(command == "add") {
    W(outputWriter, "// add")
    W(outputWriter, "@SP")
    W(outputWriter, "AM=M-1")
    W(outputWriter, "D=M")
    W(outputWriter, "A=A-1")
    W(outputWriter, "M=M+D")

  } else if(command == "sub") {
    W(outputWriter, "// sub")
    W(outputWriter, "@SP")
    W(outputWriter, "AM=M-1")
    W(outputWriter, "D=M")
    W(outputWriter, "A=A-1")
    W(outputWriter, "M=M-D")

  } else if(command == "neg") {
    W(outputWriter, "// neg")
    W(outputWriter, "@SP")
    W(outputWriter, "A=M-1")
    W(outputWriter, "M=-M")

  } else if(command == "and") {
    W(outputWriter, "// and")
    W(outputWriter, "@SP")
    W(outputWriter, "AM=M-1")
    W(outputWriter, "D=M")
    W(outputWriter, "A=A-1")
    W(outputWriter, "M=M&D")

  } else if(command == "or") {
    W(outputWriter, "// or")
    W(outputWriter, "@SP")
    W(outputWriter, "AM=M-1")
    W(outputWriter, "D=M")
    W(outputWriter, "A=A-1")
    W(outputWriter, "M=M|D")

  } else if(command == "not") {
    W(outputWriter, "// not")
    W(outputWriter, "@SP")
    W(outputWriter, "A=M-1")
    W(outputWriter, "M=!M")

  } else if(command == "eq") {
    WriteComparison("JEQ", "EQ", outputWriter)

  } else if(command == "lt") {
    WriteComparison("JLT", "LT", outputWriter)

  } else if(command == "gt") {
    WriteComparison("JGT", "GT", outputWriter)
  }
}

function WriteComparison(jumpCommand : String, prefix : String, outputWriter : BufferedWriter) {
  var trueLabel = "TRUE_" + prefix + "_" + labelCounter
  var endLabel = "END_" + prefix + "_" + labelCounter
  labelCounter = labelCounter + 1

  W(outputWriter, "// " + prefix.toLowerCase())
  W(outputWriter, "@SP")
  W(outputWriter, "A=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "A=A-1")
  W(outputWriter, "D=M-D")
  W(outputWriter, "@" + trueLabel)
  W(outputWriter, "D;" + jumpCommand)
  W(outputWriter, "@SP")
  W(outputWriter, "A=M-1")
  W(outputWriter, "A=A-1")
  W(outputWriter, "M=0")
  W(outputWriter, "@" + endLabel)
  W(outputWriter, "0;JMP")
  W(outputWriter, "(" + trueLabel + ")")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M-1")
  W(outputWriter, "A=A-1")
  W(outputWriter, "M=-1")
  W(outputWriter, "(" + endLabel + ")")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M-1")
}

function FullLabelName(labelName : String) : String {
  if(currentFunctionName != null and currentFunctionName.length() > 0) {
    return currentFunctionName + "$" + labelName
  }
  return labelName
}

function WriteLabel(labelName : String, outputWriter : BufferedWriter) {
  var fullLabel = FullLabelName(labelName)
  W(outputWriter, "// label " + labelName)
  W(outputWriter, "(" + fullLabel + ")")
}

function WriteGoto(labelName : String, outputWriter : BufferedWriter) {
  var fullLabel = FullLabelName(labelName)
  W(outputWriter, "// goto " + labelName)
  W(outputWriter, "@" + fullLabel)
  W(outputWriter, "0;JMP")
}

function WriteIf(labelName : String, outputWriter : BufferedWriter) {
  var fullLabel = FullLabelName(labelName)
  W(outputWriter, "// if-goto " + labelName)
  W(outputWriter, "@SP")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@" + fullLabel)
  W(outputWriter, "D;JNE")
}

function WriteFunction(functionName : String, numLocalsText : String, outputWriter : BufferedWriter) {
  currentFunctionName = functionName
  var numLocals = Integer.parseInt(numLocalsText)

  W(outputWriter, "// function " + functionName + " " + numLocalsText)
  W(outputWriter, "(" + functionName + ")")

  for(i in 0..|numLocals) {
    WritePushConstant("0", outputWriter)
  }
}

function WriteCall(functionName : String, numArgsText : String, outputWriter : BufferedWriter) {
  var returnLabel = "RETURN_" + functionName + "_" + callCounter
  callCounter = callCounter + 1
  var numArgs = Integer.parseInt(numArgsText)

  W(outputWriter, "// call " + functionName + " " + numArgsText)

  // push return address
  W(outputWriter, "@" + returnLabel)
  W(outputWriter, "D=A")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")

  // push LCL
  W(outputWriter, "@LCL")
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")

  // push ARG
  W(outputWriter, "@ARG")
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")

  // push THIS
  W(outputWriter, "@THIS")
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")

  // push THAT
  W(outputWriter, "@THAT")
  W(outputWriter, "D=M")
  W(outputWriter, "@SP")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")
  W(outputWriter, "@SP")
  W(outputWriter, "M=M+1")

  // ARG = SP - 5 - nArgs
  W(outputWriter, "@SP")
  W(outputWriter, "D=M")
  W(outputWriter, "@5")
  W(outputWriter, "D=D-A")
  W(outputWriter, "@" + numArgs)
  W(outputWriter, "D=D-A")
  W(outputWriter, "@ARG")
  W(outputWriter, "M=D")

  // LCL = SP
  W(outputWriter, "@SP")
  W(outputWriter, "D=M")
  W(outputWriter, "@LCL")
  W(outputWriter, "M=D")

  // goto function
  W(outputWriter, "@" + functionName)
  W(outputWriter, "0;JMP")

  // return label
  W(outputWriter, "(" + returnLabel + ")")
}

function WriteReturn(outputWriter : BufferedWriter) {
  W(outputWriter, "// return")

  // frame = LCL
  W(outputWriter, "@LCL")
  W(outputWriter, "D=M")
  W(outputWriter, "@R13")
  W(outputWriter, "M=D")

  // ret = *(frame - 5)
  W(outputWriter, "@5")
  W(outputWriter, "A=D-A")
  W(outputWriter, "D=M")
  W(outputWriter, "@R14")
  W(outputWriter, "M=D")

  // *ARG = pop()
  W(outputWriter, "@SP")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@ARG")
  W(outputWriter, "A=M")
  W(outputWriter, "M=D")

  // SP = ARG + 1
  W(outputWriter, "@ARG")
  W(outputWriter, "D=M+1")
  W(outputWriter, "@SP")
  W(outputWriter, "M=D")

  // THAT = *(frame - 1)
  W(outputWriter, "@R13")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@THAT")
  W(outputWriter, "M=D")

  // THIS = *(frame - 2)
  W(outputWriter, "@R13")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@THIS")
  W(outputWriter, "M=D")

  // ARG = *(frame - 3)
  W(outputWriter, "@R13")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@ARG")
  W(outputWriter, "M=D")

  // LCL = *(frame - 4)
  W(outputWriter, "@R13")
  W(outputWriter, "AM=M-1")
  W(outputWriter, "D=M")
  W(outputWriter, "@LCL")
  W(outputWriter, "M=D")

  // goto ret
  W(outputWriter, "@R14")
  W(outputWriter, "A=M")
  W(outputWriter, "0;JMP")
}
