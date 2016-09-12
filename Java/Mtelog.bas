Type=StaticCode
Version=4.5
ModulesStructureVersion=1
B4J=true
@EndOfDesignText@
#ExcludeFromLibrary: True

'***************************************************************************
'*
'*  Mtelog.bas - Application logger by MacThomas Engineering
'*        
'*  Notes:
'*  ------
'*  1. Log written to:
'(
'*     B4J:  C:\Users\<user>\AppData\Roaming\<package>
'*     B4A:  Files.DirInternal
'*     B4I:  ToDo
'*
'*  2. Default log name: MTELOG.TXT
'*
'*  3. Default max log size: 100K
'*
'*  4. In release builds LogDbf() method will not output to log.  
'*     This setting can be overridden with LogDbgOn( True )

'*
'***************************************************************************

#Region BSD License
'**********************************************************************************
'*
'* Copyright (c) 2016, MacThomas Engineering
'* All rights reserved.
'*
'* You may use this file under the terms of the BSD license as follows:
'*
'* Redistribution and use in source and binary forms, with or without
'* modification, are permitted provided that the following conditions are met:
'*
'* 1. Redistributions of source code must retain the above copyright notice, this
'*    list of conditions, and the following disclaimer.
'*
'* 2. Redistributions in binary form must reproduce the above copyright notice,
'*    this list of conditions and the following disclaimer in the documentation
'*    and/or other materials provided with the distribution.
'*
'* 3. MacThomas Engineering may not be used to endorse or promote products derived 
'*    from this software without specific prior written permission.
'*
'* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
'* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
'* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
'* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
'* ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
'* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
'* LOSS OF USE, DATA, Or PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED And
'* ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
'* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
'* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
'*
'**********************************************************************************
#End Region

#Region Revision History
'**********************************************************************************
'* MTE Logger Revision History:
'*
'* No.        Who  Date        Description
'* =====      ===  ==========  ======================================================
'* 1.0.0      MTE  2016/08/05  - Begin here!
'*
'*
'**********************************************************************************
#End Region

Sub Process_Globals

	' Configurables
	Private sLogFileName="mtelog.txt" As String          ' Default log name
	Private nLogMaxSize=1024*1024 As Int                 ' 100K  
	#if RELEASE
		Private bDebugTypeEnabled = False As Boolean
	#else
		Private bDebugTypeEnabled = True As Boolean
	#End if 
	
	' Private
	Private bLogEnabled = False As Boolean
	Private sLogDirectory As String
	Private twrLogger As TextWriter
	Private ostLogger As OutputStream
	Private bLogEnabled = False As Boolean
	Private nLogSize=0 As Int 
	Private NativeMe As JavaObject

	'Constants
	Private Const FILE_APPEND=True As Boolean             'ignore
	Private CONST FILE_TRUNCATE=False As Boolean          'ignore

	' Mte logger version 
	Public Const VersionText="1.0.0" As String           

End Sub

'*--------------------------------------------------------------------------
'*
'* Start - Start logger
'*
'*
Public Sub Start As Boolean
	Private bSuccess As Boolean 

	' Set date time format
	SetDateFormat( "yyMMdd-HHmmss" )
	
	' Initialize data directory 
	SetLogDirectory
	  
	' Open log file	
	bSuccess = OpenLog
	If ( bSuccess = True ) Then 
		bLogEnabled = True
	Else 
		bLogEnabled = False 
	End If

	Return ( bLogEnabled ) 
	
End Sub


'*--------------------------------------------------------------------------
'*
'* Stop - Stop logger
'*
'*
Public Sub Stop
	
	If ( bLogEnabled = True ) Then 

		' Disable
		bLogEnabled = False
	
		' Close writer
	 	twrLogger.Close

		' Close stream
		ostLogger.Close
	
	End If 
	
End Sub 


'*--------------------------------------------------------------------------
'*
'* Inf - Log Info entry
'*
'*
Public Sub Inf( sText As String )
	
	' Log enabled? 
	If ( bLogEnabled = False ) Then Return 
	
	WriteLogEntry( "i", sText ) 
	
End Sub 

'*--------------------------------------------------------------------------
'*
'* Console - Log Info to file and console
'*
'*
Public Sub Console( sText As String )
	
	' Log enabled? 
	If ( bLogEnabled = False ) Then Return 
	
	WriteLogEntry( "i", sText ) 
	Log( sText )
	
End Sub 


'*--------------------------------------------------------------------------
'*
'* Dbg - Log debug entry
'*
'*
Public Sub Dbg( sText As String )

	' Log enabled? 
	If ( bDebugTypeEnabled = False Or bLogEnabled = False ) Then Return 

	WriteLogEntry( "d", sText ) 
	Log( sText ) 
	
End Sub 

'*--------------------------------------------------------------------------
'*
'* Err - Log error
'*
'*
Public Sub Err( sText As String )

	' Log enabled? 
	If ( bLogEnabled = False ) Then Return 

	WriteLogEntry( "e", sText ) 
	Log( sText ) 

End Sub 

'*--------------------------------------------------------------------------
'*
'* DbgOn - Enable debug logging in RELEASE builds. Or disable in DEBUG
'*
'*            By default debug log entries are discarded in RELEASE mode.
'*            This allows flag to be overriden.
'*
'*
Public Sub DbgOn( bEnable As Boolean )
		
	bDebugTypeEnabled = bEnable
			
End Sub 


'*--------------------------------------------------------------------------
'*
'* SetFileName - Set log file name
'*
'*
Public Sub SetFileName( sFileName As String ) 
	
	sLogFileName = sFileName 
		 
End Sub

'*--------------------------------------------------------------------------
'*
'* SetMaxSize - Set max log file size
'*
'*
Public Sub SetMaxSize( nMaxSize As Int ) As Int
	Private Const MIN_LOG_SIZE=1024 * 10 As Int
	Private nOldMaxSize As Int 
	
	' Save old value before change
	nOldMaxSize = nLogMaxSize

	' Greater then 10k ?	
	If ( nMaxSize > MIN_LOG_SIZE ) Then 
		nLogMaxSize = nMaxSize
	End If 	
		
	Return ( nOldMaxSize )
		 
End Sub


'*--------------------------------------------------------------------------
'*
'* SetDateFormat - Set date format that prefixes log entries
'*
'*
Private Sub SetDateFormat( sDateFormat As String )

	If ( NativeMe.IsInitialized = False )  Then 
		#if B4J
			NativeMe = Me 
		#else
			#if B4A 
				NativeMe.InitializeStatic(Application.PackageName & ".mte") 
			#else 
				NativeMe = Platform not supported
			#end if 
		#end if
	End If
		
	' Set date time format
    NativeMe.RunMethod("mteSetDateTimeFormat", Array( sDateFormat ) )

End Sub

'*--------------------------------------------------------------------------
'*
'* SetLogDirectory - Build path to log directory
'*
'*
Private Sub SetLogDirectory

#if B4J

	Private jo As JavaObject
	Private sAppName As String
	Private search As Matcher

	' Init javaobject
	jo.InitializeStatic("anywheresoftware.b4a.BA")

	' Extract last section of package name.  This is our app name
	search = Regex.Matcher("\w+$", jo.GetField("packageName") )
	search.Find
	sAppName = search.Match
	
	' Build path to log directory (e.g. C:\Users\Stan\AppData\Roaming\<packagename> )
	sLogDirectory = File.DirData( sAppName )

#else 

	#if B4A 

		' Default to internal directory
		sLogDirectory = File.DirInternal 
	
	#else 
	
		' Force compiler to generate an error
		sLogDirectory = Platform Not Supported
	
	#end if 

#end if 
	


End Sub

'*--------------------------------------------------------------------------
'*
'* OpenLog  - Open the log file
'*
'*
Private Sub OpenLog As Boolean
	Private bAppendFlag As Boolean
	Private bSuccess=True As Boolean 
	
	' Get size of existing log.  Will return zero if file doesn't exist
	nLogSize = File.Size( sLogDirectory, sLogFileName )
	
	' If over max log size set flag to truncate
	If ( nLogSize > nLogMaxSize  ) Then 
		bAppendFlag = FILE_TRUNCATE 
		nLogSize = 0
	Else 
		bAppendFlag = FILE_APPEND 
	End If 
	
	Try 
		' Open file
		ostLogger = File.OpenOutput( sLogDirectory, sLogFileName, bAppendFlag )

		' Connect stream to text writer	
		twrLogger.Initialize(ostLogger )
		
		'twrLogger.Initialize2(ostLogger, "ISO-8859-1")

	Catch 
		' Set flag on error
		bSuccess = False		
	End Try
	
	Return ( bSuccess ) 
		
End Sub

'*--------------------------------------------------------------------------
'*
'* CloseLog - Close log file
'*
'*
Private Sub CloseLog

	' Close writer
 	twrLogger.Close

	' Close stream
	ostLogger.Close
		
End Sub

'*--------------------------------------------------------------------------
'*
'* ResetLog - Close and re-open the log
'*
'*
Private Sub ResetLog As Boolean
	Private bSuccess As Boolean 
	
	' Close log
	CloseLog
	
	' Re-open the log 
	bSuccess = OpenLog

	' Log back in service?	
	If ( bSuccess = True )  Then 
		bLogEnabled = True 
		Inf( "<-- Reset Log --")
	Else
		bLogEnabled = False
	End If
	
	Return ( bSuccess ) 
		
End Sub

'*--------------------------------------------------------------------------
'*
'* WriteLogEntry() - Write entry to log file
'*
'*
Private Sub WriteLogEntry( sEntryType As String, sText As String )
	Private sbOutText As StringBuilder
	Private sDateText As String
	Private bSuccess As Boolean

	' If max log size then reset and start new log
	If ( nLogSize > nLogMaxSize ) Then 
		bSuccess = ResetLog
		If ( bSuccess = False ) Then 
			Return
		End If 
	End If

	' Get formatted date time string
	sDateText = NativeMe.RunMethod("mteGetDateTimeString", Null)

	' Build log entry
	sbOutText.Initialize
	sbOutText.Append(sDateText)
	sbOutText.Append("[")
	sbOutText.Append(sEntryType)
	sbOutText.Append("]: ")
	sbOutText.Append( sText )

	' Write and flush
	twrLogger.WriteLine( sbOutText.ToString )
	twrLogger.Flush

	' Add to file size
	nLogSize = nLogSize + sbOutText.Length + 1   ' +1 For end of line character 0xA
		
End Sub 

#If JAVA

import java.util.Date;
import java.text.SimpleDateFormat;

// Store date format
public static SimpleDateFormat mteDateFormat;

/*--------------------------------------------------------------------------
'*
'* mteSetDateTimeFormat()
'*
*/
public static void mteSetDateTimeFormat( String formatSpec ) {
	mteDateFormat = new SimpleDateFormat( formatSpec );
}

/*--------------------------------------------------------------------------
'*
'* mteGetDateTimeString()
'*
*/
public static String mteGetDateTimeString() {
    return mteDateFormat.format( new Date() );
}

#End If


	
	