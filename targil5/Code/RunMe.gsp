package scratch

uses javax.swing.JOptionPane

var inputPath = JOptionPane.showInputDialog(
  "Enter path to a .jack file or folder:"
)

if (inputPath == null) {
  print("No input path was provided")
  return
}

inputPath = inputPath.trim()

if (inputPath.length() == 0) {
  print("No input path was provided")
  return
}

if (inputPath.startsWith("\"") and inputPath.endsWith("\"")) {
  inputPath = inputPath.substring(
    1,
    inputPath.length() - 1
  )
}

JackCompiler.compile(inputPath)

print("Done")