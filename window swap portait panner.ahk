#Persistent
CoordMode, Mouse, Screen  ; Use screen coordinates relative to the primary monitor
#InstallMouseHook  ; Ensure mouse events are captured globally

Speed := 1  ; Speed in pixels per interval (default is now 1)
StuckThreshold := 10000  ; 10 seconds (10,000 ms)
MinChange := 2  ; Minimum pixel change required to not be considered stuck
IsPaused := false  ; Tracks whether the movement is paused
IsHidden := false  ; Tracks whether the cursor is hidden

LastX := 0  ; Stores the last X position
LastMoveTime := A_TickCount  ; Tracks the last time the cursor moved by MinChange
Direction := 1  ; 1 for right, -1 for left

SetTimer, MoveCursor, 20  ; Move the cursor every 20 ms (50 times per second)
SetTimer, CheckForStuck, 100  ; Check if the cursor is stuck every 100 ms
SetTimer, UpdateCursorPosition, 100  ; Update the cursor position and GUI every 100 ms

; Create GUI
Gui, Add, Text, x10 y10 w200 h20 vPositionDisplay, Cursor X Position: 0
Gui, Add, Text, x10 y40 w200 h20 vDirectionDisplay, Current Direction: Right
Gui, Add, Text, x10 y70 w200 h20, Set Movement Speed (Pixels per Interval):
Gui, Add, Edit, x10 y100 w200 h20 vSpeedInput, %Speed%
Gui, Add, Button, x10 y130 w200 h30 gSetSpeed, Set Speed
Gui, Add, Button, x10 y170 w200 h30 vPauseResumeBtn gPauseResume, Pause
Gui, Add, Button, x10 y210 w200 h30 gHideCursor, Hide  ; Hide button
Gui, Show, w220 h280, Cursor Movement Control

Return

; Move the cursor
MoveCursor:
    if (IsPaused)
        Return  ; Do not move the cursor if paused

    MouseGetPos, x, y
    NewX := x + (Speed * Direction)  ; Move cursor in the current direction
    MouseMove, NewX, y, 0  ; Move cursor without animation (instant move)
Return

; Check if the cursor is stuck
CheckForStuck:
    if (IsPaused)
        Return  ; Do not check for stuck if paused

    MouseGetPos, CurrentX, y

    ; Check if the X position changed by more than MinChange
    if (Abs(CurrentX - LastX) > MinChange) {
        LastMoveTime := A_TickCount  ; Update the last move time
        LastX := CurrentX  ; Update the last known X position
    }

    ; If the cursor has been stuck for more than the threshold, reverse direction
    if (A_TickCount - LastMoveTime > StuckThreshold) {
        Direction := -Direction  ; Reverse the direction
        LastMoveTime := A_TickCount  ; Reset the timer
        Gosub, UpdateDirectionDisplay  ; Update the GUI to show the new direction
    }
Return

; Update the GUI with the current X position and direction of the cursor
UpdateCursorPosition:
    MouseGetPos, x, y  ; Get the current cursor position
    GuiControl,, PositionDisplay, Cursor X Position: %x%
Return

; Set the speed when the user inputs a new speed in the GUI
SetSpeed:
    Gui, Submit, NoHide  ; Get the value from the input field
    Speed := SpeedInput  ; Update the Speed variable
Return

; Pause/Resume the cursor movement
PauseResume:
    IsPaused := !IsPaused  ; Toggle pause state

    ; Update the button text based on the pause state
    if (IsPaused) {
        GuiControl,, PauseResumeBtn, Resume
    } else {
        GuiControl,, PauseResumeBtn, Pause
    }
Return

; Hide the cursor when the "Hide" button is clicked and minimize the GUI
HideCursor:
    if (!IsHidden) {
        SystemCursor(0)  ; Hide the system cursor
        IsHidden := true
        Gui, Minimize  ; Minimize the GUI
    }
Return

; Detect global mouse click and make the cursor visible again, restore the GUI
~LButton::  ; The tilde (~) modifier allows the mouse click to pass through normally
~RButton::  ; Right-click to restore cursor visibility as well
    if (IsHidden) {
        SystemCursor(1)  ; Show the system cursor
        IsHidden := false
        Gui, Show  ; Restore the GUI
        WinActivate  ; Bring the GUI to the front
    }
Return

; Update the direction display in the GUI
UpdateDirectionDisplay:
    GuiControl,, DirectionDisplay, % "Current Direction: " (Direction > 0 ? "Right" : "Left")
Return

; Close the script when the GUI is closed
GuiClose:
    SystemCursor(1)  ; Ensure the cursor is restored when exiting
    ExitApp
Return

; Function to control system cursor visibility
SystemCursor(OnOff=1)   ; INIT = "I","Init"; OFF = 0,"Off"; TOGGLE = -1,"T","Toggle"; ON = others
{
    static AndMask, XorMask, $, h_cursor
        ,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13 ; system cursors
        , b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13   ; blank cursors
        , h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13   ; handles of default cursors
    if (OnOff = "Init" or OnOff = "I" or $ = "")       ; init when requested or at first call
    {
        $ = h                                          ; active default cursors
        VarSetCapacity( h_cursor,4444, 1 )
        VarSetCapacity( AndMask, 32*4, 0xFF )
        VarSetCapacity( XorMask, 32*4, 0 )
        system_cursors = 32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650
        StringSplit c, system_cursors, `,
        Loop %c0%
        {
            h_cursor   := DllCall( "LoadCursor", "Ptr",0, "Ptr",c%A_Index% )
            h%A_Index% := DllCall( "CopyImage", "Ptr",h_cursor, "UInt",2, "Int",0, "Int",0, "UInt",0 )
            b%A_Index% := DllCall( "CreateCursor", "Ptr",0, "Int",0, "Int",0
                , "Int",32, "Int",32, "Ptr",&AndMask, "Ptr",&XorMask )
        }
    }
    if (OnOff = 0 or OnOff = "Off" or $ = "h" and (OnOff < 0 or OnOff = "Toggle" or OnOff = "T"))
        $ = b  ; use blank cursors
    else
        $ = h  ; use the saved cursors

    Loop %c0%
    {
        h_cursor := DllCall( "CopyImage", "Ptr",%$%%A_Index%, "UInt",2, "Int",0, "Int",0, "UInt",0 )
        DllCall( "SetSystemCursor", "Ptr",h_cursor, "UInt",c%A_Index% )
    }
}
