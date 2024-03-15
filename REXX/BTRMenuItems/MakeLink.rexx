/*
   Create symbolic links for selected icons
*/

ADDRESS WORKBENCH
OPTIONS RESULTS

GETATTR WINDOWS.ACTIVE VAR active_window
GETATTR WINDOWS.0 VAR root_window

/*
   Since there's no path attribute available for an icon, we need to guess it
   by combining window and icon names. Unfortunately, this gives us no way to find
   the path for the icons which were left out.
*/
IF active_window == root_window THEN DO
  ADDRESS COMMAND 'RequestChoice TITLE "Make link" BODY "Cannot make a link from the',
                  'root window.*nPlease put the icon(s) away first." GADGETS "_OK" >NIL:'
  EXIT 10
END

/*
   Append a trailing slash to the path if needed
   FIXME: is there a nicer way to do it?
*/
IF RIGHT(active_window, 1) == ':' THEN DO
  basedir = active_window
END
ELSE DO
  basedir = active_window'/'
END

active_window = escape(active_window)
GETATTR WINDOW.ICONS.SELECTED NAME '"'active_window'"' STEM icons_list
infos_count = 0

DO i = 0 TO (icons_list.COUNT - 1)
  /*
     There seems to be a nasty bug in Workbench 3.2 that causes all contents
     of the destination drawer to be removed when a link is deleted.
     To prevent this, we simply don't allow linking of drawers or volumes.
  */
  IF (icons_list.i.TYPE ~== 'TOOL' & icons_list.i.TYPE ~== 'PROJECT') THEN DO
    ADDRESS COMMAND 'RequestChoice TITLE "Make link" BODY "Cannot make a link to',
                    '*"'escape(icons_list.i.NAME)'*".*nOnly tools and projects can be linked."',
                    'GADGETS "_OK" >NIL:'
    EXIT 10
  END

  name_base = icons_list.i.NAME' link'
  name_dest = name_base
  
  /*
     Search for an available name for both a link and its icon
     FIXME: EXISTS() reports dangling softlinks as non-existent, which makes
            COPY and MAKELINK fail. Need to a workaround.
  */
  suffix = 0
  DO WHILE (EXISTS(basedir||name_dest) | EXISTS(basedir||name_dest'.info'))
    suffix = suffix + 1
    name_dest = name_base' 'suffix
  END

  path_src = basedir||icons_list.i.NAME
  path_dest = basedir||name_dest

  /* Copy icon if exists */
  IF EXISTS(path_src'.info') THEN DO
    ADDRESS COMMAND 'Copy FROM "'escape(path_src)'.info" TO "'escape(path_dest)'.info"'
    /* Store it for rearrangement */
    link_icons.infos_count = name_dest
    infos_count = infos_count + 1
  END

  ADDRESS COMMAND 'MakeLink FROM "'escape(path_dest)'" TO "'escape(path_src)'" SOFT'
END

/* Rearrange existing icons */
MENU WINDOW '"'active_window'"' INVOKE WINDOW.UPDATE
DO i = 0 TO (infos_count - 1)
  ICON WINDOW '"'active_window'"' NAME '"'link_icons.i'"' DOWN 15 RIGHT 15 SELECT
  MENU WINDOW '"'active_window'"' INVOKE ICONS.UNSNAPSHOT
  ICON WINDOW '"'active_window'"' NAME '"'link_icons.i'"' UNSELECT
END

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
