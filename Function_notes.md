# Function Notes

Source: https://www.autoitscript.com/autoit3/docs/function_notes.htm
Retrieved: 2026-09-27

Functions in AutoIt are first class objects. Among other things, that means you can assign a function to a variable, pass it around as an argument or return from another function.  
Aside from certain specific scope-regarding declaration rules (being that the names of the built-in functions are *reserved* and of UDFs' can be overwritten only locally), the names of functions do not have special status in the language.

```autoit
#include <MsgBoxConstants.au3>

Local $vFunc = MsgBox

$vFunc($MB_OK, "Hi there!", "Lovely day today.")
```

```autoit
Call(_Test)

Func _Test()
	ConsoleWrite("! Testing" & @CRLF)
EndFunc
```

## Optional parameters

Many functions contain optional parameters that can be omitted. If you wish to specify an optional parameter, however, all preceding parameters must be specified!  
For example, consider *[Run](https://www.autoitscript.com/autoit3/docs/functions/Run.htm) ( "filename", ["workingdir" [, flag]] )*. If you wish to specify the *flag*, you **must** specify a *workingdir*.  

When an optional parameter needs to be defined and is preceded by one or more optional parameters, the default value must be given for that parameter. Generally speaking functions should accept the [Default](https://www.autoitscript.com/autoit3/docs/keywords/Default.htm) keyword when you wish to use the default parameter. See the corresponding optional parameter description for more details.

Many Win\_\_\_ functions contain an optional parameter "text". This parameter is intended to help differentiate between windows that have identical titles.  

## Success/failure indication of internal AutoIt functions

Some functions use the **Return value** to indicate success/failure, others set the **@error flag**. Some do both....  

If the **Return value** method is used, the Help file will specify the expected value for success/failure - but the success value is typically non-zero to allow easy to read code...  

```autoit
If SomeUserFunc() Then ;...function worked.
If Not SomeUserFunc() Then ;...function failed.
```

When the documentation states that the return value = none, AutoIt always returns a value to avoid errors. 1 is usually the value returned, but you should not depend on this return value.  

If the **@error flag** method is used, @error = 0 always indicates success. Other @error values indicate a problem and are defined in the Help file for the function.  

```autoit
Local $sFileRead = FileReadLine("C:\someFile.txt")
If @error = -1 Then ; End-of-file was reached.
```

If a function uses the **@error flag** method, the flag should be checked immediately after the function returns as @error will be reset to 0 when entering the next function. No attempt to use or access the function return value should be made if the @error flag has been set as in that case the return value is generally undefined...  

## Success/failure indication of user-written functions

The return value, @error, and @extended macros are normally set by the author using the [Return](https://www.autoitscript.com/autoit3/docs/keywords/Func.htm)/[SetError](https://www.autoitscript.com/autoit3/docs/SetError.htm)/[SetExtended](https://www.autoitscript.com/autoit3/docs/SetExtended.htm) functions within the code. See the documentation for the specific user-written library to determine the specific values that are used.
