package scratch

uses java.nio.file.Files
uses java.nio.file.Paths
uses java.util.ArrayList

class JackAnalyzer {

  static function analyze(source : String) : void {
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
      var tokenizer = new JackTokenizer(filePath)

      var tokenOutputPath = buildTokenOutputPath(filePath)
      tokenizer.writeTokensXml(tokenOutputPath)
      print("Created: " + tokenOutputPath)

      var engine = new CompilationEngine(tokenizer.allTokens())
      var parseOutputPath = buildParseOutputPath(filePath)
      engine.writeXml(parseOutputPath)
      print("Created: " + parseOutputPath)
    }
  }

  static function collectJackFiles(source : String) : List<String> {
    var result = new ArrayList<String>()
    var path = Paths.get(source)

    if (Files.isDirectory(path)) {
      for (p in Files.newDirectoryStream(path, "*.jack")) {
        result.add(p.toString())
      }
    } else {
      if (source.toLowerCase().endsWith(".jack")) {
        result.add(source)
      }
    }

    return result
  }

  static function buildTokenOutputPath(filePath : String) : String {
    return filePath.substring(0, filePath.length() - 5) + "T.xml"
  }

  static function buildParseOutputPath(filePath : String) : String {
    return filePath.substring(0, filePath.length() - 5) + ".xml"
  }
}