#Requires AutoHotkey v2.1-a
#Include ".\classes\Base.ahk"
#Include ".\classes\GuiThemes.ahk"
#Include ".\classes\Ini.ahk"
#Include ".\classes\View.ahk"

;comment out this line to disable Dumper's GUI error capturing
Dump.gui.enableErrorCapturing()

;uncomment this line if you're used to the legacy syntax
; dumpGui(values*) => dump.gui(values*)

/**
 * Dump console, string, msgbox, tip, examples
 * dump(var, var2, var3 ...)
 * dump(var).exit()
 * dump.loud(var)
 * dump.string(var)
 * dump.msgBox(var)
 * dump.tip(var)
 * dump.exeTime(callback, iterations)
 *
 * Dump GUI examples
 * dump.gui(var, var2, var3)
 * dump.gui.addToSysTray()
 * dump.gui.enableErrorCapturing()
 * dump.gui.enableQuietDumps()
 * dump.gui.setHotkey("F1")
 * dump.gui.exeTime(callback, iterations)
 *
 * dump.gui.quiet(var, var2, var3 ...)
 * dump.gui.pause(var, var2, var3 ...)
 *
 * dump.gui.success(str)
 * dump.gui.successQuiet(str)
 * dump.gui.danger(str)
 * dump.gui.dangerQuiet(str)
 */

class dump extends DumperBase {
  static CONSOLE_THEME := "dracula", ;dracula, vscode, loud, or make your own
    GUI_THEME := "dracula", ;dracula, vscode, or make your own
    INDENT_VALUE := "  "

  class gui {
    static log := "",
      errorCapturing := 0,
      quietDumps := 0

    static __New(theme := Dump.GUI_THEME) {
      this.ini := DumperIni()
      RegisterSystemCallbacks()
      this.view := DumperView(theme, this.ini)

      RegisterSystemCallbacks() {
        OnMessage(Dump.WM_EXITSIZEMOVE, WindowMovedOrResized)

        WindowMovedOrResized(wParam, lParam, msg, hwnd) {
          if (this.view.gui != "") {
            if (hwnd == this.view.gui.hwnd) {
              this.view.gui.GetPos(
                &this.ini.scriptName.x,
                &this.ini.scriptName.y,
                &this.ini.scriptName.w,
                &this.ini.scriptName.h,
              )
              this.ini.save()
            }
          }
        }
      }
    }

    static Call(values*) {
      this.view.prepareLog()
      for value in values {
        Dump.gui.log .= dump.string(value)
      }
      if (! this.quietDumps) {
        this.view.show()
      }

      return this
    }

    static addToSysTray() {
      A_TrayMenu.Insert("E&xit", "&Dumper", (*) => this.view.show())
      A_TrayMenu.Insert("&Dumper", "")
      A_TrayMenu.Insert("E&xit", "")

      return this
    }

    static captureError(exception, mode) {
      this.view.prepareLog()
      Dump.gui.log .= exception.Message ? "Error: " exception.Message "`n`n" : ""
      Dump.gui.log .= exception.Extra ? "Specifically: " exception.Extra "`n`n" : ""
      Dump.gui.log .= exception.Line ? "Line #" exception.Line ": " RegExReplace(RegExReplace(exception.Stack, "s)\R.+", ""), "^.+\[.+\]\s", "") "`n" : ""

      Loop read, exception.File {

        if (
          (A_Index >= (exception.Line - 3) && A_Index <= exception.Line)
          || (A_Index <= (exception.Line + 3) && A_Index >= exception.Line)
        ) {
          Dump.gui.log .= (
            (A_Index == exception.Line ? "" : " " )
            A_Index ": " A_LoopReadLine "`n"
          )
        }
      }

      Dump.gui.log .= exception.Stack ? "`n" 'Call Stack: `n' exception.Stack : ""
      this.view.show()

      if (this.ini.scriptName.stopOnError) {
        this.view.pauseHandler(1)
      }
      return true
    }

    static exeTime(callback, iterations := 1) {
      this.Call(DumperBase.exe(callback, iterations))
    }

    static highlight(str, highlight := "success") {
      this.view.prepareLog()
      wrapper := (highlight == "success" ? " ** " : " * ")
      Dump.gui.log .= wrapper str wrapper "`n"
      if (! this.quietDumps) {
        this.view.show()
      }

      return this
    }

    static enableErrorCapturing() {
      Dump.gui.errorCapturing := 1
      OnError(LogError)

      LogError(exception, mode) {
        return this.captureError(exception, mode)
      }

      return this
    }

    static enableQuietDumps(on := 1) {
      this.quietDumps := on

      return this
    }

    static setHotkey(hk, hotIfCallback := (*) => true) {
      HotIf((*) => hotIfCallback())
        Hotkey(hk, (*) => this.view.toggle())
      HotIf

      return this
    }

    static quiet(values*) => this.enableQuietDumps().Call(values*).enableQuietDumps(0)
    static pause(values*) => this.Call(values*).view.pauseHandler(0)

    static success(str) => this.highlight(str)
    static successQuiet(str) => this.enableQuietDumps().highlight(str).enableQuietDumps(0)
    static danger(str) => this.highlight(str, "danger")
    static dangerQuiet(str) => this.enableQuietDumps().highlight(str, "danger").enableQuietDumps(0)
  }
}
