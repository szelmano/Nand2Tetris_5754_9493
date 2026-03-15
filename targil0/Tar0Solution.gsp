uses java.io.File
uses java.io.BufferedWriter
uses java.io.FileWriter
uses java.math.BigDecimal
uses java.util.Scanner

// Global variables to keep track of total buy and sell amounts
var totalBuy : BigDecimal = BigDecimal.ZERO
var totalSell : BigDecimal = BigDecimal.ZERO

// Path to the folder containing the VM input files
var folderPath = "C:\\Users\\owner\\Documents\\Tar0"
var folder = new File(folderPath)

// Validate that the folder exists and is a directory
if(not folder.exists() or not folder.isDirectory()) {
  print("Folder not found")
  return
}

// Create the output file with the same name as the folder
var outputFileName = folder.Name + ".asm"
var outputFile = new File(folder, outputFileName)
var writer = new BufferedWriter(new FileWriter(outputFile))

try {
  // Get all files in the folder
  var files = folder.listFiles()

  if(files != null) {
    for(f in files) {
      // Process only .vm files
      if(f.isFile() and f.Name.toLowerCase().endsWith(".vm")) {
        ProcessVmFile(f, writer)
      }
    }
  }

  // Write total results to the output file
  var buyLine = "TOTAL BUY: " + totalBuy.toPlainString()
  var sellLine = "TOTAL SELL: " + totalSell.toPlainString()

  writer.write(buyLine)
  writer.newLine()
  writer.write(sellLine)
  writer.newLine()

  // Print totals to the console
  print(buyLine)
  print(sellLine)

} finally {
  // Ensure the writer is always closed
  writer.close()
}

// Reads and processes a single VM file
function ProcessVmFile(vmFile : File, outputWriter : BufferedWriter) {

  // Write the file name without the ".vm" extension
  var fileNameWithoutExtension = vmFile.Name.substring(0, vmFile.Name.length() - 3)
  outputWriter.write(fileNameWithoutExtension)
  outputWriter.newLine()

  var scanner = new Scanner(vmFile)

  try {
    while(scanner.hasNextLine()) {

      // Read the next line and remove extra spaces
      var line = scanner.nextLine().trim()

      // Skip empty lines
      if(line.length() == 0) {
        continue
      }

      // Split the command line into parts
      var parts = line.split(" ")

      var command = parts[0]
      var productName = parts[1]
      var amount = Integer.parseInt(parts[2])
      var price = new BigDecimal(parts[3])

      // Call the appropriate handler based on the command
      if(command == "buy") {
        HandleBuy(productName, amount, price, outputWriter)
      } else if(command == "sell") {
        HandleSell(productName, amount, price, outputWriter)
      }
    }
  } finally {
    // Close scanner after finishing reading the file
    scanner.close()
  }
}

// Handles a BUY command
function HandleBuy(productName : String, amount : int, price : BigDecimal, outputWriter : BufferedWriter) {

  // Calculate total price for this buy command
  var sum = price.multiply(new BigDecimal(amount))

  // Write formatted output to the file
  outputWriter.write("### BUY " + productName + " ###")
  outputWriter.newLine()
  outputWriter.write(sum.toPlainString())
  outputWriter.newLine()

  // Update total buy amount
  totalBuy = totalBuy.add(sum)
}

// Handles a SELL command
function HandleSell(productName : String, amount : int, price : BigDecimal, outputWriter : BufferedWriter) {

  // Calculate total price for this sell command
  var sum = price.multiply(new BigDecimal(amount))

  // Write formatted output to the file
  outputWriter.write("$$$ SELL " + productName + " $$$")
  outputWriter.newLine()
  outputWriter.write(sum.toPlainString())
  outputWriter.newLine()

  // Update total sell amount
  totalSell = totalSell.add(sum)
}