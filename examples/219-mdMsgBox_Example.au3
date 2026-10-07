; Author ........: ioa747
; Modified ......: mLipok
#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
; Functional copy/adaptation of the GitHub example by ioa747.
; Source: https://github.com/ioa747/NetWebView2Lib/blob/main/examples/019-mdMsgBox_Example.au3
#include "219-mdMsgBox.au3"

Global $bSmoke = False
If $CmdLine[0] > 0 Then $bSmoke = ($CmdLine[1] = "--smoke")
Global $iAnswer = _MDBox_Show("# Markdown" & @CRLF & "Choose a **button**. Unicode sample: ąćęłńóśźż 😀", "219 - Markdown MsgBox", "Yes|No|Cancel", 0, 0, $bSmoke)
Global $iError = @error, $iExtended = @extended
ConsoleWrite("MD_BOX result=" & $iAnswer & " error=" & $iError & " extended=" & $iExtended & @CRLF)
If $bSmoke Then
	If $iError Or $iAnswer <> 1 Then Exit 1
	ConsoleWrite("MD_BOX_SMOKE_OK arch=" & (@AutoItX64 ? "x64" : "x86") & @CRLF)
Else
	_MDBox_Show("## Markdown" & @CRLF & "This message closes automatically after **3 seconds**.", "Timeout", "OK", 3000)
EndIf
Exit 0
