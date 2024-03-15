/*
   Create an archive with selected icons
*/

ADDRESS WORKBENCH
OPTIONS RESULTS

LHA = "C:lha"
GETATTR WINDOWS.ACTIVE VAR active_window
GETATTR WINDOWS.0 VAR root_window
GETATTR WINDOW.ICONS.SELECTED NAME '"'escape(active_window)'"' STEM icons_list

/*
   Since there's no path attribute available for an icon, we need to guess it
   by combining window and icon names. Unfortunately, this gives us no way to find
   the path for the icons which were left out.
*/
IF active_window == root_window THEN DO
  ADDRESS COMMAND 'RequestChoice TITLE "Compress" BODY "Cannot compress icons from the',
                  'root window.*nPlease put the icon(s) away first." GADGETS "_OK" >NIL:'
  EXIT 10
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

IF icons_list.COUNT == 1 THEN DO
  name_base = icons_list.0.NAME
END
ELSE DO
  name_base = "Archive"
END

name_dest = name_base

/* Search for an available name for the archive */
suffix = 0
DO WHILE EXISTS(basedir||name_dest'.lha')
  suffix = suffix + 1
  name_dest = name_base' 'suffix
END

lha_args = 'a -r "'basedir||name_dest'.lha"'
DO i = 0 TO (icons_list.COUNT - 1)
    path = basedir||icons_list.i.NAME
    lha_args = lha_args' "'escape(path)'"'
    IF EXISTS(path'.info') THEN DO
    	lha_args = lha_args' "'escape(path'.info')'"'
    END
END

ADDRESS COMMAND LHA' 'lha_args

MENU WINDOW '"'active_window'"' INVOKE WINDOW.UPDATE

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
