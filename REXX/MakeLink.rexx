/*
   Create symbolic links for selected icons
*/

ADDRESS WORKBENCH
OPTIONS RESULTS

GETATTR WINDOWS.ACTIVE VAR active_window
GETATTR WINDOWS.0 VAR root_window
GETATTR WINDOW.ICONS.SELECTED NAME '"'active_window'"' STEM icons_list

IF active_window == root_window THEN DO
  ADDRESS COMMAND 'RequestChoice TITLE "Make link" BODY "Please put the icon(s) away first" GADGETS "OK" >NIL:'
  EXIT 10
END

icons_count = 0
DO i = 0 TO (icons_list.count - 1)
  /* FIXME: is there a nicer way to do it? */
  IF RIGHT(active_window, 1) == ':' THEN DO
    basedir = active_window
  END
  ELSE DO
    basedir = active_window'/'
  END

  name_base = icons_list.i.NAME' link'
  name_dest = name_base
  
  /* Search for an available name for both a link and its icon */
  suffix = 0
  DO WHILE (EXISTS(basedir||name_dest) | EXISTS(basedir||name_dest'.info'))
    suffix = suffix + 1
    name_dest = name_base' 'suffix
  END

  path_src = basedir||icons_list.i.NAME
  path_dest = basedir||name_dest

  /* Copy icon if exists */
  IF EXISTS(path_src'.info') THEN DO
  
    ADDRESS COMMAND 'Copy FROM "'path_src'.info" TO "'path_dest'.info"'
    /* Store it for rearrangement */
    link_icons.icons_count = name_dest
    icons_count = icons_count + 1
  END

  ADDRESS COMMAND 'MakeLink FROM "'path_dest'" TO "'path_src'" SOFT'
END

/* Rearrange existing icons */
MENU WINDOW '"'active_window'"' INVOKE WINDOW.UPDATE
DO i = 0 TO (icons_count - 1)
  ICON WINDOW '"'active_window'"' NAME '"'link_icons.i'"' DOWN 15 RIGHT 15 SELECT
  MENU WINDOW '"'active_window'"' INVOKE ICONS.SNAPSHOT
  ICON WINDOW '"'active_window'"' NAME '"'link_icons.i'"' UNSELECT
END
