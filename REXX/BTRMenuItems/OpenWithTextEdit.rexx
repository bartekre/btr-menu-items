/*
   Opens selected files with TextEdit
*/

ADDRESS WORKBENCH
OPTIONS RESULTS

EDITOR = "SYS:Tools/TextEdit"
GETATTR WINDOWS.ACTIVE VAR active_window
GETATTR WINDOWS.0 VAR root_window
GETATTR WINDOW.ICONS.SELECTED NAME '"'escape(active_window)'"' STEM icons_list

/*
   Since there's no path attribute available for an icon, we need to guess it
   by combining window and icon names. Unfortunately, this gives us no way to find
   the path for the icons which were left out.
*/
IF active_window == root_window THEN DO
  ADDRESS COMMAND 'RequestChoice TITLE "Open with TextEdit" BODY "Cannot open icons from the',
                  'root window.*nPlease put the icon(s) away first." GADGETS "_OK" >NIL:'
  EXIT 10
END

DO i = 0 TO (icons_list.COUNT - 1)
  IF (icons_list.i.TYPE ~== 'PROJECT' & icons_list.i.TYPE ~== 'TOOL') THEN DO
    ADDRESS COMMAND 'RequestChoice TITLE "Open with TextEdit" BODY "*"'icons_list.i.NAME'*" is neither a project',
                    'nor a tool" GADGETS "_OK" >NIL:'
    EXIT 10
  END
END

/*
   Append a trailing slash to the path if needed
*/
IF RIGHT(active_window, 1) == ':' THEN DO
  basedir = active_window
END
ELSE DO
  basedir = active_window'/'
END

editor_args = ''
DO i = 0 TO (icons_list.COUNT - 1)
    path = basedir||icons_list.i.NAME
    editor_args = editor_args' "'escape(path)'"'
END

ADDRESS COMMAND EDITOR' 'editor_args

EXIT

/* Escape string to use it with a shell command */
escape: PROCEDURE
  PARSE ARG subject
  /* Find quotes and asterisks */
  pos = MAX(LASTPOS('"', subject), LASTPOS('*', subject)) - 1
  DO WHILE pos >= 0 THEN DO
    /* Prepend an asterisk to escape the character */
    subject = INSERT('*', subject, pos)
    pos = MAX(LASTPOS('"', subject, pos), LASTPOS('*', subject, pos)) - 1
  END
RETURN subject
