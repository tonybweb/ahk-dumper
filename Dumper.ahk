#Requires AutoHotkey v2
#Include ".\classes\Base.ahk"

/**
 * Dump examples
 * dump(var, var2, var3 ...)
 * dump(var).exit()
 * dump.loud(var)
 * dump.string(var)
 * dump.msgBox(var)
 * dump.tip(var)
 */

class dump extends DumperBase {
  static CONSOLE_THEME := "dracula", ;dracula, vscode, loud, or make your own
    INDENT_VALUE := "  "
}
