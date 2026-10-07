#Tidy_ILC_Pos=44
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include <String.au3>
#include "..\WebView2.au3"

Exit _SmokeJSON()

; #INTERNAL_USE_ONLY# ============================================================================================================
; Name ..........: _SmokeJSON
; Description ...: Checks empty, escaped, Unicode and large CDP JSON string values without starting WebView2.
; Syntax ........: _SmokeJSON()
; Parameters ....: None.
; Return values .: 0 if all cases pass; 1 on a mismatch or unexpected error.
; Author ........: mLipok
; Modified ......:
; Remarks .......: Captures @error immediately; tests the export reader's recursion-limit regression.
; Related .......: __WebView2_JSON_GetStringProperty
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _SmokeJSON()
	Local $iResult = 1
	Do
		Local $aCases[10][3] = [['{"data":""}', 'data', ''], _
				['{"data":"abc"}', 'data', 'abc'], _
				['{"data":"a\"b\\c\n"}', 'data', 'a"b\c' & @LF], _
				['{"data":"tail\\"}', 'data', 'tail\'], _
				['{"data":"ąćę"}', 'data', 'ąćę'], _
				['{"a.b":"literal","ab":"other"}', 'a.b', 'literal'], _
				['{"data":"\u0105\u0107\u0119"}', 'data', 'ąćę'], _
				['{"data":"\ud83d\ude00"}', 'data', '😀'], _
				['{"data":"C:\\new\\folder"}', 'data', 'C:\new\folder'], _
				['{"data":"literal \\n \\f \\u0105"}', 'data', 'literal \n \f \u0105']]
		Local $sValue = '', $iError = 0
		For $i = 0 To UBound($aCases) - 1
			$sValue = __WebView2_JSON_GetStringProperty($aCases[$i][0], $aCases[$i][1])
			$iError = @error
			If $iError Or $sValue <> $aCases[$i][2] Then
				ConsoleWrite('CASE_FAIL index=' & $i & ' error=' & $iError & ' value=' & $sValue & @CRLF)
				ExitLoop
			EndIf
		Next
		If $i < UBound($aCases) Then ExitLoop
		Local $sLarge = _StringRepeat('ABCDEFGHIJKLMNOPQRSTUVWXYZ012345', 16384)
		$sValue = __WebView2_JSON_GetStringProperty('{"data":"' & $sLarge & '"}', 'data')
		$iError = @error
		If $iError Or $sValue <> $sLarge Then
			ConsoleWrite('PLAIN_FAIL error=' & $iError & ' length=' & StringLen($sValue) & @CRLF)
			ExitLoop
		EndIf
		Local $sEscaped = _StringRepeat('0123456789\n\"\\', 10000)
		Local $sExpected = _StringRepeat('0123456789' & @LF & '"\', 10000)
		$sValue = __WebView2_JSON_GetStringProperty('{"data":"' & $sEscaped & '"}', 'data')
		$iError = @error
		If $iError Or $sValue <> $sExpected Then
			ConsoleWrite('ESCAPED_FAIL error=' & $iError & ' length=' & StringLen($sValue) & @CRLF)
			ExitLoop
		EndIf
		$sValue = __WebView2_JSON_GetStringProperty('{"other":"x"}', 'data')
		$iError = @error
		If $sValue <> '' Or $iError <> 1 Then ExitLoop
		$sValue = __WebView2_JSON_GetStringProperty('{"data":"unterminated}', 'data')
		$iError = @error
		If $sValue <> '' Or $iError <> 1 Then ExitLoop
		ConsoleWrite('JSON_SMOKE_OK plain=' & StringLen($sLarge) & ' escaped=' & StringLen($sEscaped) & @CRLF)
		$iResult = 0
	Until True
	If $iResult Then ConsoleWrite('JSON_SMOKE_FAIL' & @CRLF)
	Return $iResult
EndFunc   ;==>_SmokeJSON
