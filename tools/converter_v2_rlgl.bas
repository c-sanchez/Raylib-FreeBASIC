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
    
    ' Cache to prevent duplicate constant definitions (common in C #ifdef blocks)
    sEmittedConsts(1 To 2000) As String
    iEmittedConstCount As Integer
    
    bCliteralEmitted As Integer ' Boolean
    sDetectedVersion As String
    bIsRlgl As Integer ' Boolean flag for RLGL mode

    Declare Constructor()
    Declare Function sMapType(ByVal sCType As String) As String
    Declare Function sProcessDefine(ByVal sLine As String, ByRef bShouldPrint As Integer) As String
    Declare Function sProcessStruct(ByVal iFileNum As Integer, ByVal sHeaderLine As String) As String
    Declare Function sProcessEnum(ByVal iFileNum As Integer, ByVal sHeaderLine As String) As String
    Declare Function sProcessCallback(ByVal sLine As String) As String
    Declare Function sProcessFunction(ByVal sLine As String) As String
    Declare Function sConvertArgs(ByVal sArgs As String) As String
    Declare Function sConvertSingleArg(ByVal sArg As String) As String
    
    Declare Sub Convert(ByVal sInputPath As String, ByVal sOutputPath As String)
End Type

Constructor RaylibConverter()
    iMouseConstCount = 0
    iEmittedConstCount = 0
    bCliteralEmitted = 0
    sDetectedVersion = "5.5" ' Default fallback
    bIsRlgl = 0
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
        Case "bool": sFBBase = "bool"
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
    End Select
    
    ' Special handling for char*
    If sBaseType = "char" Then
        If iPtrCount = 1 Then
            If bIsConst Then Return "const zstring ptr" Else Return "zstring ptr"
        End If
        If iPtrCount = 2 Then
            ' char ** -> string array/list
            If bIsConst Then Return "const zstring ptr ptr" Else Return "zstring ptr ptr"
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
    
    ' Filter out unwanted internal C defines
    If InStr(sLine, "RAYLIB_H") > 0 Or InStr(sLine, "RLGL_H") > 0 Then Return ""
    If InStr(sLine, "RAYLIB_VERSION") > 0 And InStr(sLine, "RAYLIB_VERSION_") = 0 Then Return ""
    If InStr(sLine, "RLGL_VERSION") > 0 Then Return ""
    If InStr(sLine, "RLAPI") > 0 Then Return ""
    If InStr(sLine, "__declspec") > 0 Then Return ""
    If InStr(sLine, "defined") > 0 Then Return ""
    If InStr(sLine, "return") > 0 Then Return ""
    If InStr(sLine, "RL_BOOL_TYPE") > 0 Then Return ""
    If InStr(sLine, "__attribute__") > 0 Then Return ""
    If InStr(sLine, "#error") > 0 Then Return ""
    If InStr(sLine, "#undef") > 0 Then Return ""
    
    ' Allocators - Skip in RLGL as they are likely in raylib.bi
    If InStr(sLine, "RL_MALLOC") > 0 Or InStr(sLine, "RL_CALLOC") > 0 Or _
       InStr(sLine, "RL_REALLOC") > 0 Or InStr(sLine, "RL_FREE") > 0 Then
        If bIsRlgl Then Return "" 
        bShouldPrint = -1
        Return sLine
    End If
    
    ' CLITERAL macro
    If InStr(sLine, "CLITERAL") > 0 And InStr(sLine, "define CLITERAL") > 0 Then
        If bCliteralEmitted = 0 Then
            bCliteralEmitted = -1
            bShouldPrint = -1
            Return "#define CLITERAL(type) (type)"
        Else
            Return ""
        End If
    End If
    
    ' Constants - Prevent duplicates if handling RLGL (which relies on raylib.bi)
    If InStr(sLine, "PI 3.14") > 0 Then
        If bIsRlgl Then Return "" ' Skip PI in RLGL
        bShouldPrint = -1
        Return "const PI = 3.14159265358979323846f"
    End If
    If InStr(sLine, "DEG2RAD") > 0 Then
        If bIsRlgl Then Return ""
        bShouldPrint = -1
        Return "const DEG2RAD = (PI / 180.0f)"
    End If
    If InStr(sLine, "RAD2DEG") > 0 Then
        If bIsRlgl Then Return ""
        bShouldPrint = -1
        Return "const RAD2DEG = (180.0f / PI)"
    End If
    
    ' Color Defines
    If InStr(sLine, "CLITERAL(Color)") > 0 Then
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
    
    ' MOUSE_ constants (buffer aliases to output after enum)
    If InStr(sLine, "MOUSE_") > 0 Then
        Dim iSpace1 As Integer = InStr(sLine, " ")
        Dim sRest1 As String = Trim(Mid(sLine, iSpace1 + 1))
        Dim iSpace2 As Integer = InStr(sRest1, " ")
        If iSpace2 > 0 Then
            Dim sDefName As String = Left(sRest1, iSpace2 - 1)
            Dim sVal As String = Trim(Mid(sRest1, iSpace2 + 1))
            ' If val is not number (it is an alias like MOUSE_BUTTON_LEFT), buffer it
            If Val(sVal) = 0 And Left(sVal, 1) <> "0" And sVal <> "0" Then
                iMouseConstCount += 1
                sMouseConsts(iMouseConstCount) = "const " + sDefName + " = " + sVal
                Return ""
            End If
        End If
    End If
    
    ' General Defines handling
    Dim iSpace1 As Integer = InStr(sLine, " ")
    Dim sRest1 As String = Trim(Mid(sLine, iSpace1 + 1))
    Dim iSpace2 As Integer = InStr(sRest1, " ")
    
    If iSpace2 > 0 Then
        Dim sKey As String = Left(sRest1, iSpace2 - 1)
        Dim sVal As String = Trim(Mid(sRest1, iSpace2 + 1))
        
        ' Ignore empty defines like #define RLAPI
        If sVal = "" Then Return ""
        If InStr(sKey, "(") > 0 Then Return ""

        ' Output as constant or define
        bShouldPrint = -1
        
        ' If the value looks like a number, make it a const
        If (Val(sVal) <> 0) Or (sVal = "0") Or (Left(sVal, 2) = "0x") Or (Left(sVal, 1) = "0" And Val(sVal)=0) Then
             ' Fix Hex format: 0x -> &h
             sVal = sReplace(sVal, "0x", "&h")
             
             ' DUPLICATE CHECK
             Dim j As Integer
             For j = 1 To iEmittedConstCount
                 If sEmittedConsts(j) = sKey Then Return "" ' Already emitted, skip
             Next
             
             iEmittedConstCount += 1
             sEmittedConsts(iEmittedConstCount) = sKey
             
             Return "const " + sKey + " = " + sVal
        Else
             ' It's likely a function alias or type alias mapping
             Return "#define " + sKey + " " + sVal
        End If
    End If
    
    Return ""
End Function

Function RaylibConverter.sProcessStruct(ByVal iFileNum As Integer, ByVal sHeaderLine As String) As String
    Dim sName As String = sGetBetween(sHeaderLine, "struct ", " {")
    If sName = "" Then sName = sGetBetween(sHeaderLine, "struct ", "{")
    sName = sTrim(sName)
    
    ' Special checks
    If sName = "Color" Then sName = "RayColor"
    
    ' If we are processing rlgl, skip Matrix because it is defined in raylib.bi
    If bIsRlgl And sName = "Matrix" Then
        Dim sDump As String
        Do
            Line Input #iFileNum, sDump
            sDump = sTrim(sDump)
            If Left(sDump, 1) = "}" Then Exit Do
        Loop
        Return ""
    End If
    
    Dim sRet As String = ""
    sRet += !"\n" + "type " + sName + !"\n"
    
    ' Member Name Cache to handle #if blocks resulting in duplicate member names
    Dim sMembers(1 To 200) As String
    Dim iMemberCount As Integer = 0
    
    Dim sLine As String
    Do
        Line Input #iFileNum, sLine
        sLine = sTrim(sLine)
        
        ' Ignore preprocessor lines inside struct (like #if defined(...))
        If Left(sLine, 1) = "#" Then Continue Do
        
        If Left(sLine, 1) = "}" Then Exit Do
        If sLine = "" Or Left(sLine, 2) = "//" Then Continue Do
        
        ' Shim for Camera3D union
        If sName = "Camera3D" And InStr(sLine, "int projection") > 0 Then
            sRet += "  union" + !"\n"
            sRet += "    projection as long" + !"\n"
            sRet += "    type as long" + !"\n"
            sRet += "  end union" + !"\n"
            Continue Do
        End If
        
        Dim sClean As String = sReplace(sLine, ";", "")
        
        ' Identify Member Name
        Dim sVarName As String = ""
        Dim sRawType As String = ""
        Dim sCount As String = ""
        Dim bIsArray As Integer = 0
        
        ' Check Array [4]
        Dim iBracket As Integer = InStr(sClean, "[")
        If iBracket > 0 Then
            Dim iEndBracket As Integer = InStr(sClean, "]")
            sCount = Mid(sClean, iBracket + 1, iEndBracket - iBracket - 1)
            Dim sLeft As String = Left(sClean, iBracket - 1)
            sVarName = sGetLastWord(sLeft)
            sRawType = sRemoveLastWord(sLeft)
            bIsArray = -1
        Else
            ' Standard single var or multi-var line
            ' Simplified here: assuming one var per line for RLGL/complex headers, or parsing the first one
             If InStr(sClean, ",") > 0 Then
                Dim iComma As Integer = InStr(sClean, ",")
                Dim sFirstChunk As String = Left(sClean, iComma - 1)
                sVarName = sGetLastWord(sFirstChunk)
                sRawType = sRemoveLastWord(sFirstChunk)
                ' Note: This logic only grabs the first var in "float x, y;". 
                ' For full robustness we'd need to loop, but for dup checking let's focus on name.
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
        
        ' DUPLICATE MEMBER CHECK
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
        
        ' -- Code Generation --
        Dim sFBType As String = sMapType(sRawType)
        
        If bIsArray Then
             If InStr(sRawType, "char") > 0 And InStr(sRawType, "unsigned") = 0 Then
                sRet += "  " + sVarName + " as zstring * " + sCount + !"\n"
            Else
                sRet += "  " + sVarName + "(0 to " + Str(Val(sCount) - 1) + ") as " + sFBType + !"\n"
            End If
        Else
             ' Handle comma separated "float x, y;" properly now for output
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
                
                ' Process rest
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
                    
                    ' Add extra vars to cache too
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
            ' } Name;
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
    ' typedef void (*Name)(args);
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
    
    ' Ptr logic for return type
    Dim iRetPtrCount As Integer = iCountChar(sRetPart, "*")
    Dim sBaseRet As String = sReplace(sRetPart, "*", "")
    sBaseRet = sTrim(sBaseRet)
    
    ' Fix for LoadFileDataCallback returning ubyte ptr (unsigned char *)
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

Function RaylibConverter.sProcessFunction(ByVal sLine As String) As String
    Dim sClean As String = sReplace(sReplace(sLine, "RLAPI ", ""), ";", "")
    sClean = sTrim(sClean)
    
    Dim iParen As Integer = InStr(sClean, "(")
    Dim sPreParen As String = Left(sClean, iParen - 1)
    Dim sArgsPart As String = Mid(sClean, iParen + 1)
    If Len(sArgsPart) > 0 Then sArgsPart = Left(sArgsPart, Len(sArgsPart) - 1)
    
    Dim sFuncName As String = sGetLastWord(sPreParen)
    Dim sRetTypeC As String = sRemoveLastWord(sPreParen)
    
    ' Handle pointers attached to function name
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
    
    ' Split by comma
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
    
    ' Move stars from name to type
    Dim iPtrs As Integer = iCountChar(sVarName, "*")
    sVarName = sReplace(sVarName, "*", "")
    
    If sVarName = "color" Then sVarName = "RayColor"
    
    Dim z As Integer
    For z = 1 To iPtrs
        sRawType += "*"
    Next
    
    Dim sFBType As String = ""
    
    ' Check const char ** (used in TextSplit, TextJoin, etc)
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
    
    ' Pre-scan for version and type (Raylib vs RLGL)
    bIsRlgl = 0
    iEmittedConstCount = 0 ' Reset cache
    
    Dim sLine As String
    Do Until Eof(iIn)
        Line Input #iIn, sLine
        ' Check Raylib Version
        If InStr(sLine, "#define RAYLIB_VERSION") > 0 And InStr(sLine, "RAYLIB_VERSION_") = 0 Then
            Dim iQ1 As Integer = InStr(sLine, Chr(34))
            Dim iQ2 As Integer = InStrRev(sLine, Chr(34))
            If iQ1 > 0 And iQ2 > iQ1 Then
                sDetectedVersion = Mid(sLine, iQ1 + 1, iQ2 - iQ1 - 1)
            End If
            Exit Do
        End If
        ' Check RLGL Version
        If InStr(sLine, "#define RLGL_VERSION") > 0 Then
            bIsRlgl = -1
            Dim iQ1 As Integer = InStr(sLine, Chr(34))
            Dim iQ2 As Integer = InStrRev(sLine, Chr(34))
            If iQ1 > 0 And iQ2 > iQ1 Then
                sDetectedVersion = Mid(sLine, iQ1 + 1, iQ2 - iQ1 - 1)
            End If
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
    
    If bIsRlgl Then
        Print #iOut, "#include once ""raylib.bi"""
    End If
    
    Print #iOut, ""
    Print #iOut, "#inclib ""raylib"""
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
    Else
        Print #iOut, "#define RAYLIB_H"
        Print #iOut, "#define RAYLIB_VERSION """ + sDetectedVersion + """"
        Print #iOut, "#define RLAPI"
    End If
    
    ' Insert Boolean logic from chat analysis
    Print #iOut, ""
    Print #iOut, "' Boolean emulation for C binding"
    Print #iOut, "#ifndef bool"
    Print #iOut, "    type bool as byte"
    Print #iOut, "#endif"
    Print #iOut, "#ifndef true"
    Print #iOut, "    const true = 1"
    Print #iOut, "#endif"
    Print #iOut, "#ifndef false"
    Print #iOut, "    const false = 0"
    Print #iOut, "#endif"
    Print #iOut, "#ifndef IsNot"
    Print #iOut, "    #define IsNot 0="
    Print #iOut, "#endif"
    Print #iOut, ""
    
    Do Until Eof(iIn)
        Line Input #iIn, sLine
        sLine = sTrim(sLine)
        
        If sLine = "" Then Continue Do
        
        ' Stop parsing if we hit implementation (rlgl has implementation in header)
        If InStr(sLine, "RLGL_IMPLEMENTATION") > 0 Then Exit Do
        
        If InStr(sLine, "define RL_BOOL_TYPE") > 0 Then
            Print #iOut, "#define RL_BOOL_TYPE"
            Continue Do
        End If
        
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
                ' Alias: typedef struct Name Name;
                Dim sName As String = sGetLastWord(sReplace(sLine, ";", ""))
                Dim sPrev As String = sRemoveLastWord(sReplace(sLine, ";", ""))
                
                ' Skip Matrix alias in rlgl if it exists
                If bIsRlgl And sName = "Matrix" Then Continue Do
                
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
            Print #iOut, "type " + sAlias + " as " + sSrc
            Continue Do
        End If
        
        ' Callbacks
        If Left(sLine, 7) = "typedef" And InStr(sLine, "(*") > 0 Then
            Print #iOut, sProcessCallback(sLine)
            Continue Do
        End If
        
        ' Functions
        If Left(sLine, 5) = "RLAPI" Then
            Print #iOut, sProcessFunction(sLine)
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