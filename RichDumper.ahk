#Requires AutoHotkey v2.1-a

#Include "Dumper.ahk"
#Include "Lib\RichIni.ahk"
#Include "Lib\RichThemes.ahk"
#Include "Lib\RichView.ahk"

richDumper := RichDump("dracula")
richDumper.enableErrorCapturing()

/**
 * Other Examples
 *
 * richDumper.enableQuietDumps()
 * richDumper.setHotkey("F1")
 * richDumper.addToSysTray()
 * richDumper.enableQuietDumps().setHotkey("F1", () {
 *   return WinActive("ahk_exe Code.exe")
 * })
 *
 */

dumpGui(values*) => richDumper.dump(values*)
dumpGuiSuccess(str) => richDumper.dumpHighlight(str)
dumpGuiDanger(str) => richDumper.dumpHighlight(str, "danger")

class RichDump
{
  static log := ""
  static errorCapturing := 0

  DEFAULT_THEME := "dracula"
  WM_EXITSIZEMOVE := 0x0232

  quietDumps := 0

  __New(theme := this.DEFAULT_THEME) {

    this.ini := RichIni()
    RegisterSystemCallbacks()
    this.view := RichView(theme, this.ini)

    return

    RegisterSystemCallbacks() {
      OnMessage(this.WM_EXITSIZEMOVE, WindowMovedOrResized)

      WindowMovedOrResized(wParam, lParam, msg, hwnd)
      {
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

  addToSysTray()
  {
    A_TrayMenu.Insert("E&xit", "&Dumper", (*) => this.view.show())
    A_TrayMenu.Insert("&Dumper", "")
    A_TrayMenu.Insert("E&xit", "")

    return this
  }

  captureError(exception, mode) {
    this.view.prepareLog()
    RichDump.log .= exception.Message ? "Error: " exception.Message "`n`n" : ""
    RichDump.log .= exception.Extra ? "Specifically: " exception.Extra "`n`n" : ""
    RichDump.log .= exception.Line ? "Line #" exception.Line ": " RegExReplace(RegExReplace(exception.Stack, "s)\R.+", ""), "^.+\[.+\]\s", "") "`n" : ""

    Loop read, exception.File {

      if (
        (A_Index >= (exception.Line - 3) && A_Index <= exception.Line)
        || (A_Index <= (exception.Line + 3) && A_Index >= exception.Line)
      ) {
        RichDump.log .= (
          (A_Index == exception.Line ? "" : " " )
          A_Index ": " A_LoopReadLine "`n"
        )
      }
    }

    RichDump.log .= exception.Stack ? "`n" 'Call Stack: `n' exception.Stack : ""
    this.view.show()

    if (this.ini.scriptName.stopOnError) {
      this.view.pauseHandler(1)
    }
    return true
  }

  dump(values*)
  {
    this.view.prepareLog()
    for value in values {
      RichDump.log .= dumpString(value)
    }
    if (! this.quietDumps) {
      this.view.show()
    }
  }

  dumpHighlight(str, highlight := "success")
  {
    this.view.prepareLog()
    wrapper := (highlight == "success" ? " ** " : " * ")
    RichDump.log .= wrapper str wrapper "`n"
    if (! this.quietDumps) {
      this.view.show()
    }
  }

  enableErrorCapturing()
  {
    RichDump.errorCapturing := 1
    OnError(LogError)

    LogError(exception, mode) {
      return this.captureError(exception, mode)
    }

    return this
  }

  enableQuietDumps(on := 1)
  {
    this.quietDumps := on

    return this
  }

  setHotkey(hk, hotIfCallback := (*) => true)
  {
    HotIf((*) => hotIfCallback())
      Hotkey(hk, (*) => this.view.toggle())
    HotIf

    return this
  }
}