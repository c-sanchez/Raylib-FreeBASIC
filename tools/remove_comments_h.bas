#include "crt.bi"

Dim As String inputLine, outputLine, inputFileName
Dim As Integer fhIn, fhOut
Dim As Boolean inMultilineComment = False
Dim As String buffer = ""
Dim As Boolean lastLineWasEmpty = False

inputFileName = Command(1)

If Len(inputFileName) = 0 Then
  Print "Arrastre un archivo al ejecutable o escriba el nombre:"
  Input inputFileName
End If

If Left(inputFileName, 1) = """" Then
  inputFileName = Mid(inputFileName, 2)
End If
If Right(inputFileName, 1) = """" Then
  inputFileName = Left(inputFileName, Len(inputFileName) - 1)
End If

fhIn = FreeFile
If Open(inputFileName For Input As #fhIn) <> 0 Then
  Print "Error: No se puede abrir " & inputFileName
  Sleep
  End 1
End If

fhOut = FreeFile
If Open("output.h" For Output As #fhOut) <> 0 Then
  Print "Error: No se puede crear output.h"
  Close #fhIn
  Sleep
  End 1
End If

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

  Dim As Integer i = 1
  While i <= Len(inputLine)
    If Mid(inputLine, i, 2) = "/*" And Not inMultilineComment Then
      inMultilineComment = True
      i += 2
      Continue While
    End If

    If Mid(inputLine, i, 2) = "*/" And inMultilineComment Then
      inMultilineComment = False
      i += 2
      Continue While
    End If

    If Mid(inputLine, i, 2) = "//" And Not inMultilineComment Then
      Exit While
    End If

    If Not inMultilineComment Then
      outputLine += Mid(inputLine, i, 1)
    End If

    i += 1
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

Print "Procesamiento completado. Revise output.h"
Sleep