#Requires AutoHotkey v2

#Include "Lib\ColorButton.ahk\ColorButton.ahk"
#Include "Dumper.ahk"
#Include "Lib\Ini.ahk"
#Include "Lib\RichCode\Highlighter.ahk"
#Include "Lib\RichCode\RichCode.ahk"
#Include "Lib\RichThemes.ahk"

richDumper := RichDump()
dumpGui(values*) => richDumper.dump(values*)
dumpGuiSuccess(str) => richDumper.dumpHighlight(str)
dumpGuiDanger(str) => richDumper.dumpHighlight(str, "danger")

class RichDump
{
  static log := ""

  BUTTONS := {
    H: 35,
    W: 90,
  }
  CHAR_WIDTH := 11
  DEFAULT_THEME := "dracula"
  DWMWA_USE_IMMERSIVE_DARK_MODE := 20
  EMPTY_LOG_MESSAGE := ";log empty, use ``dumpGui()`` to output to this window`n`n`n`n`n"
  FONT := "Fira Code"
  FONT_SIZE := 14
  FONT_SIZE_BTN := 12
  LINE_HEIGHT := 31
  MARGIN := 16
  WM_EXITSIZEMOVE := 0x0232
  WS_HSCROLL := 0x100000
  WS_VSCROLL := 0x200000

  allowScrollToEnd := true
  errorCapturing := 0
  iniFile := "dumper.ini"
  log := {
    lines: 0,
    lineLength: 0,
  }
  gui := ""
  settings := {
    TabSize: 2,
    Indent: "  ",
    Font: {Typeface: this.FONT, Size: this.FONT_SIZE, Bold: false},
    WordWrap: false,

    UseHighlighter: true,
    HighlightDelay: 200,
    Highlighter: Highlighter,
  }

  __New(theme := this.DEFAULT_THEME) {
    if (! RichThemes.HasProp(theme)) {
      theme := this.DEFAULT_THEME
    }
    this.theme := RichThemes.%theme%

    this.settings.guiMarginColor := this.theme.guiMarginColor
    this.settings.FGColor := this.theme.FGColor
    this.settings.BGColor := this.theme.BGColor
    this.settings.colors := this.theme.colors

    IniHandler()
    RegisterSystemCallbacks()

    return

    IniHandler()
    {
      if (! A_IsCompiled) {
        this.iniFile := StrSplit(A_LineFile, "RichDumper.ahk")[1] this.iniFile
      }

      this.ini := Ini(this.iniFile)
      iniDefaults := {
        w: width := A_ScreenWidth / 4 + (this.MARGIN * 2),
        h: height := A_ScreenHeight / 3 (this.MARGIN * 2),
        x: A_ScreenWidth / 2 - (width / 2),
        y: A_ScreenHeight / 2 - (height / 2),
        stopOnError: 1
      }

      if (this.ini.hasFile) {
        AddMissingDefaults()
      } else {
        SaveDefaults()
      }

      this.iniSection := this.ini.contents.%A_ScriptName%

      SaveDefaults() {
        this.ini.contents := {
          %A_ScriptName%: iniDefaults
        }
        this.ini.save()
      }
      AddMissingDefaults()
      {
        saveIni := false
        if (! this.ini.contents.HasProp(A_ScriptName)) {
          this.ini.contents.%A_ScriptName% := {}
        }
        for propertyName, value in iniDefaults.OwnProps() {
          if (! this.ini.contents.%A_ScriptName%.HasProp(propertyName)) {
            this.ini.contents.%A_ScriptName%.%propertyName% := value
            saveIni := true
          }
        }
        if (saveIni) {
          this.ini.save()
        }
      }
    }

    RegisterSystemCallbacks() {
      OnMessage(this.WM_EXITSIZEMOVE, WindowMovedOrResized)

      WindowMovedOrResized(wParam, lParam, msg, hwnd)
      {
        if (this.gui != "") {
          if (hwnd == this.gui.hwnd) {
            this.gui.GetPos(
              &this.iniSection.x,
              &this.iniSection.y,
              &this.iniSection.w,
              &this.iniSection.h,
            )
            this.ini.save()
          }
        }
      }
    }
  }

  addToSysTray()
  {
    A_TrayMenu.Insert("E&xit", "&Dumper", (*) => this.showGui())
    A_TrayMenu.Insert("&Dumper", "")
    A_TrayMenu.Insert("E&xit", "")
  }

  captureError(exception, mode) {
    this.prepareLog()
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
    this.showGui()

    if (this.iniSection.stopOnError) {
      this.pauseHandler(1)
    }
    return true
  }

  dump(values*)
  {
    this.prepareLog()
    for value in values {
      RichDump.log .= dumpString(value)
    }
    this.showGui()
  }

  dumpHighlight(str, highlight := "success")
  {
    this.prepareLog()
    wrapper := (highlight == "success" ? " ** " : " * ")
    RichDump.log .= wrapper str wrapper "`n"
    this.showGui()
  }

  enableErrorCapturing()
  {
    this.errorCapturing := 1
    OnError(LogError)

    LogError(exception, mode) {
      return this.captureError(exception, mode)
    }
  }

  loadGui()
  {
    this.gui := Gui("+Resize +AlwaysOnTop +MinSize590x180", "Dumper - " A_ScriptName)
    this.gui.SetFont("s" this.FONT_SIZE_BTN " cFFFFFF")
    this.gui.MarginX := this.gui.MarginY := this.MARGIN
    this.gui.BackColor := this.settings.guiMarginColor
    this.gui.OnEvent("Close", (*) => this.gui.hide())
    this.gui.OnEvent("Size", (*) => PositionContents())

    this.gui.clearBtn := this.gui.AddButton("Section XM W" this.BUTTONS.W  " H" this.BUTTONS.H, "Clear")
    this.gui.clearBtn.SetColor(this.theme.buttons.default.bg, this.theme.buttons.default.fg)
    this.gui.clearBtn.OnEvent("Click", (*) => Clear())

    this.gui.pauseBtn := this.gui.AddButton("WP HP X+" this.MARGIN, "Pause")
    this.gui.pauseBtn.SetColor(this.theme.buttons.danger.bg, this.theme.buttons.danger.fg)
    this.gui.pauseBtn.OnEvent("Click", (*) => this.pauseHandler())

    if (this.errorCapturing) {
      this.gui.stopOnError := this.gui.AddCheckBox(
        "H" this.BUTTONS.H " X+" this.MARGIN " Checked" (this.iniSection.stopOnError ?? "0"),
        "Stop On Error"
      )
      this.gui.stopOnError.OnEvent("Click", (*) => StopOnErrorHandler())
    }

    this.gui.restartBtn := this.gui.AddButton("X+" this.MARGIN " W" this.BUTTONS.W  " H" this.BUTTONS.H, "Restart")
    this.gui.restartBtn.SetColor(this.theme.buttons.default.bg, this.theme.buttons.default.fg)
    this.gui.restartBtn.OnEvent("Click", (*) => Reload())

    this.gui.exitBtn := this.gui.AddButton("WP HP X+" this.MARGIN, "Exit")
    this.gui.exitBtn.SetColor(this.theme.buttons.danger.bg, this.theme.buttons.danger.fg)
    this.gui.exitBtn.OnEvent("Click", (*) => ExitApp())

    RichCode.MenuItems := []
    this.rc := RichCode(this.gui, this.settings, "Section XM W" this.iniSection.w " H" this.iniSection.h)
    DarkScrollBars()
    DarkInactiveState()

    this.gui.Show("x" A_ScreenWidth " y" A_ScreenHeight " NoActivate")

    Clear()
    {
      RichDump.log := ""
      this.rc.Text := RichDump.log
    }
    StopOnErrorHandler()
    {
      this.iniSection.stopOnError := this.gui.stopOnError.value
      this.ini.save()
    }
    DarkInactiveState() {
      DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", this.gui.hwnd, "int", this.DWMWA_USE_IMMERSIVE_DARK_MODE, "int*", 1, "int", 4)
    }
    DarkScrollBars() {
      DllCall("uxtheme\SetWindowTheme", "Ptr", this.rc._control.hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
    }
    PositionContents() {
      this.gui.GetClientPos(,, &innerWidth, &innerHeight)
      this.gui.restartBtn.Move(innerWidth - (this.MARGIN * 2) - (this.BUTTONS.W * 2))
      this.gui.exitBtn.Move(innerWidth - this.MARGIN - this.BUTTONS.W)
      this.rc._control.Move(,, innerWidth - (this.MARGIN * 2), innerHeight - (this.MARGIN * 3) - this.BUTTONS.H)
      this.setScrollBars()
    }
  }

  pauseHandler(isError := 0)
  {
    static pauseState := 0

    if (pauseState ^= 1) {
      this.gui.pauseBtn.text := "Resume"
      this.gui.pauseBtn.SetColor(this.theme.buttons.success.bg, this.theme.buttons.success.fg)
      RichDump.log .= " * " (isError ? "Stopped" : "Paused") " * `n"
    } else {
      this.gui.pauseBtn.text := "Pause"
      this.gui.pauseBtn.SetColor(this.theme.buttons.danger.bg, this.theme.buttons.danger.fg)
      RichDump.log .= " * Resumed * `n"
    }
    this.rc.Text := RichDump.log
    ControlSend("^{End}", this.rc._control)

    this.gui.pauseBtn.Redraw()

    if (isError || ! pauseState) {
      Suspend(pauseState)
    }
    Sleep(250) ;give the pause btn time to redraw
    Pause(pauseState)
  }

  prepareLog()
  {
    this.allowScrollToEnd := true
    if (RichDump.log == this.EMPTY_LOG_MESSAGE) {
      RichDump.log := ""
    }
  }

  setScrollBars()
  {
    this.rc._control.GetPos( , , &richWidth, &richHeight)

    textWidth := this.CHAR_WIDTH * this.log.lineLength
    textHeight := this.LINE_HEIGHT * this.log.lines
    if (textWidth < richWidth) {
      this.rc._control.Opt("-" this.WS_HSCROLL)
    } else {
      this.rc._control.Opt("+" this.WS_HSCROLL)
    }

    if (textHeight < richHeight) {
      this.rc._control.Opt("-" this.WS_VSCROLL)
    } else {
      this.rc._control.Opt("+" this.WS_VSCROLL)
    }
    this.rc._control.Redraw()
  }

  showGui()
  {
    firstShow := 1
    if (this.gui == "") {
      this.loadGui()
    } else {
      this.gui.show("NoActivate")
      firstShow := 0
    }
    if (RichDump.log == "") {
      RichDump.log := this.EMPTY_LOG_MESSAGE
    }
    this.rc.Text := RichDump.log
    SetLogProperties()
    SetGuiSizeAndPosition()
    ScrollToEnd()

    SetLogProperties() {
      Loop parse RichDump.log, "`n", "`r" {
        if (this.log.lineLength <= currentLength := StrLen(A_LoopField)) {
          this.log.lineLength := currentLength
        }
        this.log.lines := A_Index
      }
    }
    SetGuiSizeAndPosition() {
      if (firstShow) {
        this.gui.Move(
          this.iniSection.x,
          this.iniSection.y,
          this.iniSection.w,
          this.iniSection.h,
        )
      }
    }
    ScrollToEnd() {
      if (this.allowScrollToEnd) {
        this.allowScrollToEnd := false
        Sleep(1)
        ControlSend("^{End}", this.rc._control)
      }
    }
  }
}