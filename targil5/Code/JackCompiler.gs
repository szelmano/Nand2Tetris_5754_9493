package scratch

uses java.nio.file.Files
uses java.nio.file.Paths
uses java.util.ArrayList

class JackCompiler {

  static function compile(source : String) : void {
    if (source == null or source.trim() == "") {
      print("Error: empty path")
      return
    }

    var path = Paths.get(source)

    if (not Files.exists(path)) {
      print("Path not found: " + source)
      return
    }

    var jackFiles = collectJackFiles(source)

    if (jackFiles.Count == 0) {
      print("No .jack files found in: " + source)
      return
    }

    for (filePath in jackFiles) {
      print("Compiling: " + filePath)

      var tokenizer = new JackTokenizer(filePath)

      var tokenOutputPath =
        buildTokenOutputPath(filePath)

      tokenizer.writeTokensXml(tokenOutputPath)

      print("Created: " + tokenOutputPath)

      var xmlEngine =
        new CompilationEngine(tokenizer.allTokens())

      var parseOutputPath =
        buildParseOutputPath(filePath)

      xmlEngine.writeXml(parseOutputPath)

      print("Created: " + parseOutputPath)

      var vmEngine =
        new CompilationEngine(tokenizer.allTokens())

      var vmOutputPath =
        buildVmOutputPath(filePath)

      vmEngine.writeVm(vmOutputPath)

      print("Created: " + vmOutputPath)
    }

    print("Compilation finished")
  }

  private static function collectJackFiles(
    source : String
  ) : List<String> {

    var result = new ArrayList<String>()
    var path = Paths.get(source)

    if (Files.isDirectory(path)) {
      for (
        filePath in Files.newDirectoryStream(
          path,
          "*.jack"
        )
      ) {
        result.add(filePath.toString())
      }

    } else if (
      source.toLowerCase().endsWith(".jack")
    ) {
      result.add(source)
    }

    return result
  }

  private static function buildTokenOutputPath(
    filePath : String
  ) : String {

    return filePath.substring(
      0,
      filePath.length() - 5
    ) + "T.xml"
  }

  private static function buildParseOutputPath(
    filePath : String
  ) : String {

    return filePath.substring(
      0,
      filePath.length() - 5
    ) + ".xml"
  }

  private static function buildVmOutputPath(
    filePath : String
  ) : String {

    return filePath.substring(
      0,
      filePath.length() - 5
    ) + ".vm"
  }
}