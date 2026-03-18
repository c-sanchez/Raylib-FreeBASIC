#include "file.bi"
#include "crt.bi" 

' --- Helper Functions ---

Function sTrim(ByVal sInput As String) As String
  Return Trim(sInput)
End Function

Function sReplace(ByVal sSource As String, ByVal sFind As String, ByVal sReplaceWith As String) As String
  Dim iPos As Integer
  Dim sTemp As String = sSource
  iPos = InStr(sTemp, sFind)
  While iPos > 0
    sTemp = Left(sTemp, iPos - 1) + sReplaceWith + Mid(sTemp, iPos + Len(sFind))
    iPos = InStr(iPos + Len(sReplaceWith), sTemp, sFind)
  Wend
  Return sTemp
End Function

Function iCountChar(ByVal sText As String, ByVal sChar As String) As Integer
  Dim iCount As Integer = 0
  Dim i As Integer
  For i = 1 To Len(sText)
    If Mid(sText, i, 1) = sChar Then iCount += 1
  Next
  Return iCount
End Function

Function sGetBetween(ByVal sSource As String, ByVal sStart As String, ByVal sEnd As String) As String
  Dim iStart As Integer = InStr(sSource, sStart)
  If iStart = 0 Then Return ""
  Dim iEnd As Integer = InStr(iStart + Len(sStart), sSource, sEnd)
  If iEnd = 0 Then Return ""
  Return Mid(sSource, iStart + Len(sStart), iEnd - (iStart + Len(sStart)))
End Function

Function sGetLastWord(ByVal sText As String) As String
  Dim sTemp As String = Trim(sText)
  Dim iSpace As Integer = InStrRev(sTemp, " ")
  If iSpace = 0 Then Return sTemp
  Return Mid(sTemp, iSpace + 1)
End Function

Function sRemoveLastWord(ByVal sText As String) As String
  Dim sTemp As String = Trim(sText)
  Dim iSpace As Integer = InStrRev(sTemp, " ")
  If iSpace = 0 Then Return ""
  Return Left(sTemp, iSpace - 1)
End Function

' --- Main Converter Struct ---

Type RaylibConverter
  sMouseConsts(1 To 200) As String
  iMouseConstCount As Integer
  
  ' Cache to prevent duplicate definitions
  sEmittedConsts(1 To 2000) As String
  iEmittedConstCount As Integer
  
  bCliteralEmitted As Integer
  sDetectedVersion As String
  
  ' Context flags
  bIsRlgl As Integer 
  bIsRaymath As Integer
  bIsRaygui As Integer

  Declare Constructor()
  Declare Function sMapType(ByVal sCType As String) As String
  Declare Function sProcessDefine(ByVal sLine As String, ByRef bShouldPrint As Integer) As String
  Declare Function sProcessStruct(ByVal iFileNum As Integer, ByVal sHeaderLine As String) As String
  Declare Function sProcessEnum(ByVal iFileNum As Integer, ByVal sHeaderLine As String) As String
  Declare Function sProcessCallback(ByVal sLine As String) As String
  Declare Function sProcessFunction(ByVal sLine As String, ByVal sPrefix As String) As String
  Declare Function sConvertArgs(ByVal sArgs As String) As String
  Declare Function sConvertSingleArg(ByVal sArg As String) As String
  Declare Sub SkipCFunctionBody(ByVal iFileNum As Integer, ByVal sCurrentLine As String)
  
  Declare Sub Convert(ByVal sInputPath As String, ByVal sOutputPath As String)
End Type

Constructor RaylibConverter()
  iMouseConstCount = 0
  iEmittedConstCount = 0
  bCliteralEmitted = 0
  sDetectedVersion = "5.5" ' Default fallback
  bIsRlgl = 0
  bIsRaymath = 0
  bIsRaygui = 0
End Constructor

Function RaylibConverter.sMapType(ByVal sCType As String) As String
  Dim sClean As String = sTrim(sCType)
  Dim bIsConst As Integer = 0
  
  If Left(sClean, 5) = "const" Then
    bIsConst = -1
    sClean = sTrim(Mid(sClean, 6))
  End If
  
  ' Count pointers
  Dim iPtrCount As Integer = iCountChar(sClean, "*")
  Dim sBaseType As String = sReplace(sClean, "*", "")
  sBaseType = sTrim(sBaseType)
  
  Dim sFBBase As String = sBaseType
  
  Select Case sBaseType
    Case "int": sFBBase = "long"
    Case "bool": sFBBase = "RL_BOOL" 
    Case "float": sFBBase = "single"
    Case "double": sFBBase = "double"
    Case "void": sFBBase = "any"
    Case "char": sFBBase = "byte"
    Case "unsigned int": sFBBase = "ulong"
    Case "unsigned char": sFBBase = "ubyte"
    Case "unsigned short": sFBBase = "ushort"
    Case "long": sFBBase = "long"
    Case "va_list": sFBBase = "va_list"
    Case "Color": sFBBase = "RayColor"
    Case "Quaternion": sFBBase = "Quaternion"
    Case "Matrix": sFBBase = "Matrix"
    Case "GuiStyleProp": sFBBase = "GuiStyleProp"
  End Select
  
  ' Special handling for char*
  If sBaseType = "char" Then
    If iPtrCount = 1 Then
      If bIsConst Then Return "const zstring ptr" Else Return "zstring ptr"
    End If
    If iPtrCount = 2 Then
      Return "zstring ptr ptr"
    End If
  End If
  
  Dim sSuffix As String = ""
  If iPtrCount = 1 Then sSuffix = " ptr"
  If iPtrCount = 2 Then sSuffix = " ptr ptr"
  
  If bIsConst And iPtrCount > 0 Then
    Return "const " + sFBBase + sSuffix
  End If
  
  Return sFBBase + sSuffix
End Function

Function RaylibConverter.sProcessDefine(ByVal sLine As String, ByRef bShouldPrint As Integer) As String
  bShouldPrint = 0
  
  ' Filter out headers and internal macros
  If InStr(sLine, "RAYLIB_H") > 0 Or InStr(sLine, "RLGL_H") > 0 Or InStr(sLine, "RAYMATH_H") > 0 Or InStr(sLine, "RAYGUI_H") > 0 Then Return ""
  If InStr(sLine, "_VERSION") > 0 Then Return ""
  If InStr(sLine, "RLAPI") > 0 Or InStr(sLine, "RMAPI") > 0 Or InStr(sLine, "RAYGUIAPI") > 0 Then Return ""
  If InStr(sLine, "__declspec") > 0 Then Return ""
  If InStr(sLine, "defined") > 0 Then Return ""
  If InStr(sLine, "return") > 0 Then Return ""
  If InStr(sLine, "RL_BOOL_TYPE") > 0 Then Return ""
  If InStr(sLine, "__attribute__") > 0 Then Return ""
  If InStr(sLine, "#error") > 0 Then Return ""
  If InStr(sLine, "#undef") > 0 Then Return ""
  
  ' Math macros to ignore (since we declare functions or they exist in raylib.bi)
  If bIsRaymath Then
    If InStr(sLine, "MatrixToFloat") > 0 Then Return ""
    If InStr(sLine, "Vector3ToFloat") > 0 Then Return ""
  End If

  ' Allocators - Skip in RLGL/Raymath/Raygui
  If InStr(sLine, "RL_MALLOC") > 0 Or InStr(sLine, "RL_CALLOC") > 0 Or _
     InStr(sLine, "RL_REALLOC") > 0 Or InStr(sLine, "RL_FREE") > 0 Or _
     InStr(sLine, "RAYGUI_MALLOC") > 0 Or InStr(sLine, "RAYGUI_FREE") > 0 Then
    If bIsRlgl Or bIsRaymath Or bIsRaygui Then Return "" 
    bShouldPrint = -1
    Return sLine
  End If
  
  ' Constants - Prevent duplicates
  If InStr(sLine, "PI ") > 0 Or InStr(sLine, "PI 3.14") > 0 Then
    If bIsRlgl Or bIsRaymath Or bIsRaygui Then Return "" 
    bShouldPrint = -1
    Return "const PI = 3.14159265358979323846f"
  End If
  If InStr(sLine, "DEG2RAD") > 0 Then
    If bIsRlgl Or bIsRaymath Or bIsRaygui Then Return ""
    bShouldPrint = -1
    Return "const DEG2RAD = (PI / 180.0f)"
  End If
  If InStr(sLine, "RAD2DEG") > 0 Then
    If bIsRlgl Or bIsRaymath Or bIsRaygui Then Return ""
    bShouldPrint = -1
    Return "const RAD2DEG = (180.0f / PI)"
  End If
  If InStr(sLine, "EPSILON") > 0 Then
    If bIsRaymath Then Return "" 
  End If
  
  ' Raygui Specific Macros
  If bIsRaygui Then
    If InStr(sLine, "RAYGUI_ICON_SIZE") > 0 Then
       bShouldPrint = -1
       Return "const RAYGUI_ICON_SIZE = 16"
    End If
    If InStr(sLine, "RAYGUI_MAX_CONTROLS") > 0 Then
       bShouldPrint = -1
       Return "const RAYGUI_MAX_CONTROLS = 16"
    End If
  End If

  ' Color Defines (CLITERAL or RAYGUI_CLITERAL)
  If InStr(sLine, "CLITERAL(Color)") > 0 Or InStr(sLine, "RAYGUI_CLITERAL(Color)") > 0 Then
    If bCliteralEmitted = 0 And InStr(sLine, "#define CLITERAL") > 0 Then
       bCliteralEmitted = -1
       bShouldPrint = -1
       Return "#define CLITERAL(type) (type)"
    End If
    
    Dim iSpace As Integer = InStr(sLine, " ")
    Dim sRest As String = Trim(Mid(sLine, iSpace + 1))
    iSpace = InStr(sRest, " ")
    Dim sName As String = Left(sRest, iSpace - 1)
    
    Dim sFBName As String = sName
    If sName = "Color" Then sFBName = "RayColor"
    
    Dim sVals As String = sGetBetween(sLine, "{", "}")
    
    bShouldPrint = -1
    If sVals <> "" Then
      Return "#define " + sFBName + Space(10 - Len(sFBName)) + " type<RayColor>( " + sVals + " )  ' " + sName
    ElseIf InStr(sLine, "BLANK") > 0 Then
      Return "#define " + sFBName + Space(10 - Len(sFBName)) + " type<RayColor>( 0, 0, 0, 0 )          ' " + sName
    End If
  End If
  
  ' General Defines handling
  Dim iSpace1 As Integer = InStr(sLine, " ")
  Dim sRest1 As String = Trim(Mid(sLine, iSpace1 + 1))
  Dim iSpace2 As Integer = InStr(sRest1, " ")
  
  If iSpace2 > 0 Then
    Dim sKey As String = Left(sRest1, iSpace2 - 1)
    Dim sVal As String = Trim(Mid(sRest1, iSpace2 + 1))
    
    If sVal = "" Then Return ""
    If InStr(sKey, "(") > 0 Then Return "" 

    bShouldPrint = -1
    
    If (Val(sVal) <> 0) Or (sVal = "0") Or (Left(sVal, 2) = "0x") Or (Left(sVal, 1) = "0" And Val(sVal)=0) Then
       sVal = sReplace(sVal, "0x", "&h")
       
       ' DUPLICATE CHECK
       Dim j As Integer
       For j = 1 To iEmittedConstCount
         If sEmittedConsts(j) = sKey Then Return ""
       Next
       
       iEmittedConstCount += 1
       sEmittedConsts(iEmittedConstCount) = sKey
       Return "const " + sKey + " = " + sVal
    Else
       Return "#define " + sKey + " " + sVal
    End If
  End If
  
  Return ""
End Function

Function RaylibConverter.sProcessStruct(ByVal iFileNum As Integer, ByVal sHeaderLine As String) As String
  Dim sName As String = sGetBetween(sHeaderLine, "struct ", " {")
  If sName = "" Then sName = sGetBetween(sHeaderLine, "struct ", "{")
  sName = sTrim(sName)
  
  If sName = "Color" Then sName = "RayColor"
  
  ' Skip duplicate structs in sub-libs
  If (bIsRlgl Or bIsRaymath Or bIsRaygui) Then
    If sName = "Matrix" Or sName = "Vector2" Or sName = "Vector3" Or sName = "Vector4" Or sName = "Quaternion" Or _
       sName = "RayColor" Or sName = "Rectangle" Or sName = "Texture2D" Or sName = "Image" Or sName = "GlyphInfo" Or sName = "Font" Then
      ' Skip until brace close
      Dim sDump As String
      Do
        Line Input #iFileNum, sDump
        sDump = sTrim(sDump)
        If Left(sDump, 1) = "}" Then Exit Do
      Loop
      Return ""
    End If
  End If
  
  Dim sRet As String = ""
  sRet += !"\n" + "type " + sName + !"\n"
  
  Dim sMembers(1 To 200) As String
  Dim iMemberCount As Integer = 0
  
  Dim sLine As String
  Do
    Line Input #iFileNum, sLine
    sLine = sTrim(sLine)
    
    If Left(sLine, 1) = "#" Then Continue Do
    If Left(sLine, 1) = "}" Then Exit Do
    If sLine = "" Or Left(sLine, 2) = "//" Then Continue Do
    
    If sName = "Camera3D" And InStr(sLine, "int projection") > 0 Then
      sRet += "  union" + !"\n"
      sRet += "    projection as long" + !"\n"
      sRet += "    type as long" + !"\n"
      sRet += "  end union" + !"\n"
      Continue Do
    End If
    
    Dim sClean As String = sReplace(sLine, ";", "")
    
    ' Parsing vars
    Dim sVarName As String = ""
    Dim sRawType As String = ""
    Dim sCount As String = ""
    Dim bIsArray As Integer = 0
    
    Dim iBracket As Integer = InStr(sClean, "[")
    If iBracket > 0 Then
      Dim iEndBracket As Integer = InStr(sClean, "]")
      sCount = Mid(sClean, iBracket + 1, iEndBracket - iBracket - 1)
      Dim sLeft As String = Left(sClean, iBracket - 1)
      sVarName = sGetLastWord(sLeft)
      sRawType = sRemoveLastWord(sLeft)
      bIsArray = -1
    Else
       If InStr(sClean, ",") > 0 Then
        Dim iComma As Integer = InStr(sClean, ",")
        Dim sFirstChunk As String = Left(sClean, iComma - 1)
        sVarName = sGetLastWord(sFirstChunk)
        sRawType = sRemoveLastWord(sFirstChunk)
      Else
        Dim iPtrCount As Integer = iCountChar(sClean, "*")
        Dim sNoPtr As String = sReplace(sClean, "*", "")
        sVarName = sGetLastWord(sNoPtr)
        sRawType = sRemoveLastWord(sNoPtr)
        Dim i As Integer
        For i = 1 To iPtrCount
          sRawType += "*"
        Next
      End If
    End If
    
    ' Duplicate member check
    Dim bExists As Integer = 0
    Dim k As Integer
    For k = 1 To iMemberCount
      If sMembers(k) = sVarName Then 
        bExists = -1
        Exit For
      End If
    Next
    
    If bExists Then Continue Do
    
    iMemberCount += 1
    sMembers(iMemberCount) = sVarName
    
    Dim sFBType As String = sMapType(sRawType)
    
    If bIsArray Then
       If InStr(sRawType, "char") > 0 And InStr(sRawType, "unsigned") = 0 Then
        sRet += "  " + sVarName + " as zstring * " + sCount + !"\n"
      Else
        sRet += "  " + sVarName + "(0 to " + Str(Val(sCount) - 1) + ") as " + sFBType + !"\n"
      End If
    Else
      If InStr(sClean, ",") > 0 Then
        Dim iComma As Integer
        Dim sTemp As String = sClean
        Dim sFirstChunk As String = ""
        iComma = InStr(sTemp, ",")
        sFirstChunk = Left(sTemp, iComma - 1)
        Dim sVar1 As String = sGetLastWord(sFirstChunk)
        Dim sType1 As String = sRemoveLastWord(sFirstChunk)
        Dim sFBType1 As String = sMapType(sType1)
        
        sRet += "  " + sVar1 + " as " + sFBType1 + !"\n"
        
        sTemp = Mid(sTemp, iComma + 1)
        Do
          iComma = InStr(sTemp, ",")
          Dim sNextVar As String
          If iComma > 0 Then
            sNextVar = Trim(Left(sTemp, iComma - 1))
            sTemp = Mid(sTemp, iComma + 1)
          Else
            sNextVar = Trim(sTemp)
            sTemp = ""
          End If
          iMemberCount += 1
          sMembers(iMemberCount) = sNextVar
          sRet += "  " + sNextVar + " as " + sFBType1 + !"\n"
          If sTemp = "" Then Exit Do
        Loop
      Else
        sRet += "  " + sVarName + " as " + sFBType + !"\n"
      End If
    End If
    
  Loop
  sRet += "end type"
  Return sRet
End Function

Function RaylibConverter.sProcessEnum(ByVal iFileNum As Integer, ByVal sHeaderLine As String) As String
  Dim sRet As String = ""
  Dim sBody As String = ""
  Dim sEnumName As String = ""
  
  Dim sLine As String
  Do
    Line Input #iFileNum, sLine
    sLine = sTrim(sLine)
    
    If Left(sLine, 1) = "}" Then
      sEnumName = sReplace(sReplace(sLine, "}", ""), ";", "")
      sEnumName = sTrim(sEnumName)
      Exit Do
    End If
    
    Dim sClean As String = sReplace(sLine, ",", "")
    If sClean <> "" Then
      sClean = sReplace(sClean, "0x", "&h")
      sBody += "  " + sClean + !"\n"
    End If
  Loop
  
  If sEnumName <> "" Then
    sRet += !"\n" + "type " + sEnumName + " as long" + !"\n"
  End If
  sRet += "enum" + !"\n" + sBody + "end enum" + !"\n"
  
  If sEnumName = "MouseButton" And iMouseConstCount > 0 Then
    sRet += !"\n"
    Dim k As Integer
    For k = 1 To iMouseConstCount
      sRet += sMouseConsts(k) + !"\n"
    Next
    iMouseConstCount = 0
  End If
  
  Return sRet
End Function

Function RaylibConverter.sProcessCallback(ByVal sLine As String) As String
  Dim iStar As Integer = InStr(sLine, "(*")
  Dim iCloseParen As Integer = InStr(iStar, sLine, ")")
  Dim sName As String = Mid(sLine, iStar + 2, iCloseParen - iStar - 2)
  
  Dim sRetPart As String = Left(sLine, iStar - 1)
  sRetPart = sReplace(sRetPart, "typedef", "")
  sRetPart = sTrim(sRetPart)
  
  Dim iArgStart As Integer = InStr(iCloseParen, sLine, "(")
  Dim iArgEnd As Integer = InStrRev(sLine, ")")
  Dim sArgsStr As String = Mid(sLine, iArgStart + 1, iArgEnd - iArgStart - 1)
  
  Dim sFBRet As String = ""
  Dim iRetPtrCount As Integer = iCountChar(sRetPart, "*")
  Dim sBaseRet As String = sReplace(sRetPart, "*", "")
  sBaseRet = sTrim(sBaseRet)
  
  If sBaseRet = "unsigned char" And iRetPtrCount = 1 Then
    sFBRet = "ubyte ptr"
  ElseIf sBaseRet = "char" And iRetPtrCount = 1 Then
    sFBRet = "zstring ptr"
  ElseIf sBaseRet = "char" And iRetPtrCount = 0 Then
    sFBRet = "byte"
  Else
    sFBRet = sMapType(sRetPart)
  End If
  
  Dim sSubOrFunc As String = "sub"
  If sBaseRet <> "void" Or iRetPtrCount > 0 Then
    sSubOrFunc = "function"
  End If
  
  Dim sFBArgs As String = sConvertArgs(sArgsStr)
  
  Dim sOut As String = "type " + sName + " as " + sSubOrFunc + "(" + sFBArgs + ")"
  If sSubOrFunc = "function" Then
    sOut += " as " + sFBRet
  End If
  
  Return sOut
End Function

Function RaylibConverter.sProcessFunction(ByVal sLine As String, ByVal sPrefix As String) As String
  Dim sClean As String = sReplace(sLine, sPrefix, "")
  sClean = sReplace(sClean, ";", "")
  ' Remove implementation brace if present on same line
  sClean = sReplace(sClean, "{", "")
  sClean = sTrim(sClean)
  
  Dim iParen As Integer = InStr(sClean, "(")
  If iParen = 0 Then Return ""
  
  Dim sPreParen As String = Left(sClean, iParen - 1)
  Dim sArgsPart As String = Mid(sClean, iParen + 1)
  If Len(sArgsPart) > 0 And Right(sArgsPart, 1) = ")" Then sArgsPart = Left(sArgsPart, Len(sArgsPart) - 1)
  
  Dim sFuncName As String = sGetLastWord(sPreParen)
  Dim sRetTypeC As String = sRemoveLastWord(sPreParen)
  
  Dim iFuncPtrs As Integer = iCountChar(sFuncName, "*")
  If iFuncPtrs > 0 Then
    sFuncName = sReplace(sFuncName, "*", "")
    Dim z As Integer
    For z = 1 To iFuncPtrs
      sRetTypeC += "*"
    Next
  End If
  
  Dim sSubOrFunc As String = "sub"
  Dim sFBRet As String = ""
  
  If InStr(sRetTypeC, "void") = 0 Or InStr(sRetTypeC, "*") > 0 Then
    sSubOrFunc = "function"
    If sFuncName = "GetFileModTime" And InStr(sRetTypeC, "long") > 0 Then
      sFBRet = " as clong"
    Else
      sFBRet = " as " + sMapType(sRetTypeC)
    End If
  End If
  
  Dim sFBArgs As String = sConvertArgs(sArgsPart)
  
  Return "declare " + sSubOrFunc + " " + sFuncName + "(" + sFBArgs + ")" + sFBRet
End Function

Sub RaylibConverter.SkipCFunctionBody(ByVal iFileNum As Integer, ByVal sCurrentLine As String)
  Dim iBraceCount As Integer = 0
  
  ' Check current line for braces
  iBraceCount += iCountChar(sCurrentLine, "{")
  iBraceCount -= iCountChar(sCurrentLine, "}")
  
  ' If we haven't opened a brace yet but it's a function def, keep reading until we find start
  If InStr(sCurrentLine, "{") = 0 And InStr(sCurrentLine, ";") = 0 Then
    Dim sLine As String
    Do
      Line Input #iFileNum, sLine
      iBraceCount += iCountChar(sLine, "{")
      iBraceCount -= iCountChar(sLine, "}")
      If iBraceCount > 0 Then Exit Do
      If Eof(iFileNum) Then Exit Do
    Loop
  End If
  
  ' Consume block
  If iBraceCount > 0 Then
    Dim sLine As String
    Do
      Line Input #iFileNum, sLine
      iBraceCount += iCountChar(sLine, "{")
      iBraceCount -= iCountChar(sLine, "}")
      If iBraceCount <= 0 Then Exit Do
      If Eof(iFileNum) Then Exit Do
    Loop
  End If
End Sub

Function RaylibConverter.sConvertArgs(ByVal sArgs As String) As String
  If sArgs = "" Or sArgs = "void" Then Return ""
  
  Dim sRet As String = ""
  Dim sTemp As String = sArgs
  Dim bVariadic As Integer = 0
  
  If InStr(sArgs, "...") > 0 Then
    bVariadic = -1
    sTemp = sReplace(sTemp, "...", "")
    If Right(Trim(sTemp), 1) = "," Then sTemp = Left(Trim(sTemp), Len(Trim(sTemp)) - 1)
  End If
  
  Dim iComma As Integer
  Do
    iComma = InStr(sTemp, ",")
    Dim sArg As String
    If iComma > 0 Then
      sArg = Left(sTemp, iComma - 1)
      sTemp = Mid(sTemp, iComma + 1)
    Else
      sArg = sTemp
      sTemp = ""
    End If
    
    sArg = sTrim(sArg)
    If sArg <> "" Then
      If sRet <> "" Then sRet += ", "
      sRet += sConvertSingleArg(sArg)
    End If
    
    If sTemp = "" Then Exit Do
  Loop
  
  If bVariadic Then
    If sRet <> "" Then sRet += ", "
    sRet += "..."
  End If
  
  Return sRet
End Function

Function RaylibConverter.sConvertSingleArg(ByVal sArg As String) As String
  Dim sVarName As String = sGetLastWord(sArg)
  Dim sRawType As String = sRemoveLastWord(sArg)
  
  Dim iPtrs As Integer = iCountChar(sVarName, "*")
  sVarName = sReplace(sVarName, "*", "")
  
  If sVarName = "color" Then sVarName = "RayColor"
  
  Dim z As Integer
  For z = 1 To iPtrs
    sRawType += "*"
  Next
  
  Dim sFBType As String = ""
  
  Dim iStars As Integer = iCountChar(sRawType, "*")
  If InStr(sRawType, "char") > 0 And iStars = 2 Then
    If InStr(sRawType, "const") > 0 Then
      sFBType = "const zstring ptr ptr"
    Else
      sFBType = "zstring ptr ptr"
    End If
  Else
    sFBType = sMapType(sRawType)
  End If
  
  Return "byval " + sVarName + " as " + sFBType
End Function

Sub RaylibConverter.Convert(ByVal sInputPath As String, ByVal sOutputPath As String)
  Dim iIn As Integer = FreeFile
  
  If Open(sInputPath For Input As #iIn) <> 0 Then
    Print "Error opening input file: " + sInputPath
    Exit Sub
  End If
  
  ' Pre-scan 
  bIsRlgl = 0
  bIsRaymath = 0
  bIsRaygui = 0
  iEmittedConstCount = 0
  
  Dim sLine As String
  Do Until Eof(iIn)
    Line Input #iIn, sLine
    If InStr(sLine, "#define RAYLIB_VERSION") > 0 And InStr(sLine, "RAYLIB_VERSION_") = 0 Then
      Dim iQ1 As Integer = InStr(sLine, Chr(34))
      Dim iQ2 As Integer = InStrRev(sLine, Chr(34))
      If iQ1 > 0 And iQ2 > iQ1 Then sDetectedVersion = Mid(sLine, iQ1 + 1, iQ2 - iQ1 - 1)
      Exit Do
    End If
    If InStr(sLine, "#define RLGL_VERSION") > 0 Then
      bIsRlgl = -1
      Dim iQ1 As Integer = InStr(sLine, Chr(34))
      Dim iQ2 As Integer = InStrRev(sLine, Chr(34))
      If iQ1 > 0 And iQ2 > iQ1 Then sDetectedVersion = Mid(sLine, iQ1 + 1, iQ2 - iQ1 - 1)
      Exit Do
    End If
    If InStr(sLine, "#define RAYMATH_H") > 0 Then
      bIsRaymath = -1
      sDetectedVersion = "5.5"
      Exit Do
    End If
    ' Raygui detection
    If InStr(sLine, "#define RAYGUI_H") > 0 Then
      bIsRaygui = -1
      Dim sTmpVer As String = ""
      ' Try to find version
      Do 
        Line Input #iIn, sLine
        If InStr(sLine, "#define RAYGUI_VERSION ") > 0 Then
          Dim iQ1 As Integer = InStr(sLine, Chr(34))
          Dim iQ2 As Integer = InStrRev(sLine, Chr(34))
          If iQ1 > 0 And iQ2 > iQ1 Then sTmpVer = Mid(sLine, iQ1 + 1, iQ2 - iQ1 - 1)
          Exit Do
        End If
        If InStr(sLine, "#endif") > 0 Then Exit Do
      Loop
      If sTmpVer <> "" Then sDetectedVersion = sTmpVer Else sDetectedVersion = "4.0"
      Exit Do
    End If
  Loop
  Seek #iIn, 1
  
  Dim iOut As Integer = FreeFile
  If Open(sOutputPath For Output As #iOut) <> 0 Then
    Print "Error opening output file: " + sOutputPath
    Close #iIn
    Exit Sub
  End If
  
  ' Header
  Print #iOut, "#pragma once"
  Print #iOut, ""
  Print #iOut, "#include once ""crt/long.bi"""
  Print #iOut, "#include once ""crt/stdarg.bi"""
  
  If bIsRlgl Or bIsRaymath Or bIsRaygui Then
    Print #iOut, "#include once ""raylib.bi"""
  End If
  
  Print #iOut, ""
  
  If bIsRaygui Then
    Print #iOut, "#inclib ""raygui"""
  Else
    Print #iOut, "#inclib ""raylib"""
    ' Add system libraries for Windows static linking
    Print #iOut, "#ifdef __FB_WIN32__"
    Print #iOut, "  #inclib ""gdi32"""
    Print #iOut, "  #inclib ""user32"""
    Print #iOut, "  #inclib ""kernel32"""
    Print #iOut, "  #inclib ""winmm"""
    Print #iOut, "  #inclib ""shell32"""
    Print #iOut, "  #inclib ""opengl32"""
    Print #iOut, "#endif"
  End If
  
  Print #iOut, ""
  Print #iOut, "'******** changes from base ********"
  Print #iOut, "'color -> RayColor"
  Print #iOut, ""
  Print #iOut, "extern ""C"""
  Print #iOut, ""
  
  If bIsRlgl Then
    Print #iOut, "#define RLGL_H"
    Print #iOut, "#define RLGL_VERSION """ + sDetectedVersion + """"
    Print #iOut, "#define RLAPI"
  ElseIf bIsRaymath Then
    Print #iOut, "#define RAYMATH_H"
    Print #iOut, "#define RAYMATH_VERSION """ + sDetectedVersion + """"
    Print #iOut, "#define RMAPI"
  ElseIf bIsRaygui Then
    Print #iOut, "#define RAYGUI_H"
    Print #iOut, "#define RAYGUI_VERSION """ + sDetectedVersion + """"
    Print #iOut, "#define RAYGUIAPI"
  Else
    Print #iOut, "#define RAYLIB_H"
    Print #iOut, "#define RAYLIB_VERSION """ + sDetectedVersion + """"
    Print #iOut, "#define RLAPI"
  End If
  
  Print #iOut, ""
  Print #iOut, "' Define RL_BOOL type wrapper to maintain C99 compatibility"
  Print #iOut, "' and allow flexibility if using non-standard C compilers."
  Print #iOut, "#ifndef RL_BOOL"
  Print #iOut, "    type RL_BOOL as boolean"
  Print #iOut, "#endif"
  Print #iOut, ""
  
  Do Until Eof(iIn)
    Line Input #iIn, sLine
    sLine = sTrim(sLine)
    
    If sLine = "" Then Continue Do
    
    ' Stop parsing implementation block for headers like raymath or raygui
    If InStr(sLine, "RLGL_IMPLEMENTATION") > 0 Then Exit Do
    If InStr(sLine, "RAYGUI_IMPLEMENTATION") > 0 Then Exit Do
    
    ' Defines
    If Left(sLine, 1) = "#" Then
      If Left(sLine, 7) = "#define" Then
        Dim bPrint As Integer = 0
        Dim sRes As String = sProcessDefine(sLine, bPrint)
        If bPrint Then Print #iOut, sRes
      End If
      Continue Do
    End If
    
    ' Structs
    If Left(sLine, 14) = "typedef struct" Then
      If InStr(sLine, ";") > 0 Then
        ' Alias
        Dim sName As String = sGetLastWord(sReplace(sLine, ";", ""))
        Dim sPrev As String = sRemoveLastWord(sReplace(sLine, ";", ""))
        
        ' Skip duplicate aliases for common types
        If (bIsRlgl Or bIsRaymath Or bIsRaygui) And (sName = "Matrix" Or sName = "Vector2" Or sName = "Vector3" Or sName = "Vector4" Or sName = "Quaternion" Or sName = "Texture2D" Or sName = "Image" Or sName = "GlyphInfo" Or sName = "Font" Or sName = "Color" Or sName = "Rectangle") Then Continue Do
        
        If Right(sPrev, Len(sName)) = sName Then
          Print #iOut, "type " + sName + " as " + sName
        End If
      Else
        Dim sResStruct As String = sProcessStruct(iIn, sLine)
        If sResStruct <> "" Then Print #iOut, sResStruct
      End If
      Continue Do
    End If
    
    ' Enums
    If Left(sLine, 12) = "typedef enum" Then
      If InStr(sLine, "bool") > 0 And InStr(sLine, "{") > 0 And InStr(sLine, "}") > 0 Then Continue Do
      Print #iOut, sProcessEnum(iIn, sLine)
      Continue Do
    End If
    
    ' Typedef aliases
    If Left(sLine, 8) = "typedef " And InStr(sLine, "struct") = 0 And InStr(sLine, "enum") = 0 And InStr(sLine, "(*") = 0 Then
      Dim sClean As String = sReplace(sLine, ";", "")
      Dim iLastSpace As Integer = InStrRev(sClean, " ")
      Dim sAlias As String = Mid(sClean, iLastSpace + 1)
      Dim sSrc As String = Trim(Mid(sClean, 9, Len(sClean) - 9 - Len(sAlias)))
      
      ' Ignore Quaternion alias in Raymath/Raygui if already exists
      If (bIsRaymath Or bIsRaygui) And sAlias = "Quaternion" Then Continue Do
      
      Print #iOut, "type " + sAlias + " as " + sSrc
      Continue Do
    End If
    
    ' Callbacks
    If Left(sLine, 7) = "typedef" And InStr(sLine, "(*") > 0 Then
      Print #iOut, sProcessCallback(sLine)
      Continue Do
    End If
    
    ' Functions (RLAPI)
    If Left(sLine, 5) = "RLAPI" Then
      Print #iOut, sProcessFunction(sLine, "RLAPI ")
      Continue Do
    End If
    
    ' Functions (RAYGUIAPI)
    If Left(sLine, 9) = "RAYGUIAPI" Then
       Print #iOut, sProcessFunction(sLine, "RAYGUIAPI ")
       Continue Do
    End If

    ' Functions (RMAPI) for Raymath
    If Left(sLine, 5) = "RMAPI" Then
      ' Raymath functions have implementation bodies { ... }
      ' We need to generate the declare, then skip the body lines in the input file
      Print #iOut, sProcessFunction(sLine, "RMAPI ")
      SkipCFunctionBody(iIn, sLine)
      Continue Do
    End If
    
  Loop
  
  Print #iOut, ""
  Print #iOut, "end extern"
  
  Close #iIn
  Close #iOut
  Print "Conversion Complete: " + sOutputPath
End Sub

' --- Entry Point ---

Dim Shared As RaylibConverter Converter
Dim As String sArgIn = Command(1)
Dim As String sArgOut = Command(2)

If sArgIn = "" Or sArgOut = "" Then
  Print "Usage: converter input.h output.bi"
Else
  Converter.Convert sArgIn, sArgOut
End If