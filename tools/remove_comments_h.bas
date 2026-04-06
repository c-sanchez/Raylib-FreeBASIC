#include "dir.bi"
#include "file.bi"

Dim As String fileName
Dim As String fileList()
Dim As Integer fileCount = 0
Dim As Integer i, fhIn, fhOut, charIndex
Dim As String inputLine, outputLine, ch, ch2
Dim As Boolean inMultilineComment, inString, lastLineWasEmpty

If Dir("original", fbDirectory) = "" Then
  MkDir "original"
End If

fileName = Dir("*.h")
While fileName <> ""
  fileCount += 1
  ReDim Preserve fileList(1 To fileCount)
  fileList(fileCount) = fileName
  fileName = Dir()
Wend

If fileCount = 0 Then
  Print "No .h files found in the current directory."
  Sleep
  End
End If

For i = 1 To fileCount
  FileCopy fileList(i), "original/" & fileList(i)
Next

For i = 1 To fileCount
  fhIn = FreeFile
  If Open("original/" & fileList(i) For Input As #fhIn) <> 0 Then
    Print "Error reading: original/" & fileList(i)
    Continue For
  End If

  fhOut = FreeFile
  If Open(fileList(i) For Output As #fhOut) <> 0 Then
    Print "Error writing: " & fileList(i)
    Close #fhIn
    Continue For
  End If

  inMultilineComment = False
  inString = False
  lastLineWasEmpty = False

  While Not EOF(fhIn)
    Line Input #fhIn, inputLine
    outputLine = ""

    If Len(inputLine) = 0 Then
      If Not lastLineWasEmpty Then
        Print #fhOut, ""
        lastLineWasEmpty = True
      End If
      Continue While
    End If

    charIndex = 1
    While charIndex <= Len(inputLine)
      ch  = Mid(inputLine, charIndex, 1)
      ch2 = Mid(inputLine, charIndex, 2)

      ' Inside a string: handle backslash escape so \" doesn't end the string
      If inString And CBool(ch = "\") Then
        outputLine += ch2
        charIndex += 2
        Continue While
      End If

      ' Toggle string literal tracking (only outside block comments)
      If CBool(ch = Chr(34)) And Not inMultilineComment Then
        inString = Not inString
        outputLine += ch
        charIndex += 1
        Continue While
      End If

      ' Start of block comment (only outside strings)
      If CBool(ch2 = "/*") And Not inMultilineComment And Not inString Then
        inMultilineComment = True
        charIndex += 2
        Continue While
      End If

      ' End of block comment
      If CBool(ch2 = "*/") And inMultilineComment Then
        inMultilineComment = False
        charIndex += 2
        Continue While
      End If

      ' Line comment (only outside block comments and strings)
      If CBool(ch2 = "//") And Not inMultilineComment And Not inString Then
        Exit While
      End If

      If Not inMultilineComment Then
        outputLine += ch
      End If
      charIndex += 1
    Wend

    ' Strings do not span lines in C; reset state at end of each line
    inString = False

    outputLine = RTrim(outputLine)
    If Len(outputLine) > 0 Then
      Print #fhOut, outputLine
      lastLineWasEmpty = False
    ElseIf Not inMultilineComment Then
      If Not lastLineWasEmpty Then
        Print #fhOut, ""
        lastLineWasEmpty = True
      End If
    End If
  Wend

  If inMultilineComment Then
    Print "Warning: unclosed block comment in " & fileList(i)
  End If

  Close #fhIn
  Close #fhOut
  Print "Processed: " & fileList(i)
Next

Print "All files processed successfully."
Sleep