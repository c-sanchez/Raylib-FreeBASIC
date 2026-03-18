#include "crt.bi"
#include "dir.bi"
#include "file.bi"

Dim As String fileName
Dim As String fileList()
Dim As Integer fileCount = 0
Dim As Integer i, fhIn, fhOut, charIndex
Dim As String inputLine, outputLine
Dim As Boolean inMultilineComment, lastLineWasEmpty

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
      If Mid(inputLine, charIndex, 2) = "/*" And Not inMultilineComment Then
        inMultilineComment = True
        charIndex += 2
        Continue While
      End If

      If Mid(inputLine, charIndex, 2) = "*/" And inMultilineComment Then
        inMultilineComment = False
        charIndex += 2
        Continue While
      End If

      If Mid(inputLine, charIndex, 2) = "//" And Not inMultilineComment Then
        Exit While
      End If

      If Not inMultilineComment Then
        outputLine += Mid(inputLine, charIndex, 1)
      End If

      charIndex += 1
    Wend

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

  Close #fhIn
  Close #fhOut
  Print "Processed: " & fileList(i)
Next

Print "All files processed successfully."
Sleep