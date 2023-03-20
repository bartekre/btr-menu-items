/*
   Open a new Shell in a currently active window
*/

ADDRESS WORKBENCH
OPTIONS RESULTS

GETATTR WINDOWS.ACTIVE VAR active_window
CALL PRAGMA('D', active_window)
ADDRESS COMMAND 'NewShell'

EXIT
