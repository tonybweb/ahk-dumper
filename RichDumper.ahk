#Requires AutoHotkey v2

#Include "Dumper.ahk"
#Include "Lib\RichCode\Highlighter.ahk"
#Include "Lib\RichCode\RichCode.ahk"
#Include "Lib\RichThemes.ahk"

richDumper := RichDump()
dumpGui(values*) => richDumper.dump(values*)

class RichDump
{
  static log := ""

  DEFAULT_THEME := "dracula"
  EMPTY_LOG_MESSAGE := ";log empty, use ``dumpGui()`` to output to this window`n`n`n`n`n"
  FONT := "Fira Code"
  FONT_SIZE := 14
  CHAR_WIDTH := 11
  LINE_HEIGHT := 31
  MARGIN := 16
  DWMWA_USE_IMMERSIVE_DARK_MODE := 20
  WIDTH := A_ScreenWidth / 4
  HEIGHT := A_ScreenHeight / 2
  TITLE_BAR_HEIGHT := 32
  SCREEN_OFFSET := 200
  WS_HSCROLL := 0x100000
  WS_VSCROLL := 0x200000

  allowScrollToEnd := true
  log := {
    lines: 0,
    lineLength: 0,
    px: {
      x: this.WIDTH,
      y: this.HEIGHT
    },
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
    this.settings.guiMarginColor := RichThemes.%theme%.guiMarginColor
    this.settings.FGColor := RichThemes.%theme%.FGColor
    this.settings.BGColor := RichThemes.%theme%.BGColor
    this.settings.colors := RichThemes.%theme%.colors
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
    return true
  }

  dump(values*)
  {
    this.prepareLog()
    if (values.Length) {
      for value in values {
        RichDump.log .= dumpString(value) "`n"
      }
    } else {
      RichDump.log .= dumpString(values) "`n"
    }
    this.showGui()
  }

  loadGui()
  {
    this.gui := Gui("+Resize +AlwaysOnTop", "Dumper - " A_ScriptName)
    this.gui.MarginX := this.gui.MarginY := this.MARGIN
    this.gui.BackColor := this.settings.guiMarginColor
    this.gui.OnEvent("Close", (*) => this.gui.hide())
    this.gui.OnEvent("Size", (*) => SizeContents())

    RichCode.MenuItems := []
    this.rc := RichCode(this.gui, this.settings, "xm w" this.WIDTH " h" this.HEIGHT)
    DarkScrollBars()
    DarkInactiveState()

    this.gui.Show("x" A_ScreenWidth " y" A_ScreenHeight " NoActivate")

    DarkInactiveState() {
      DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", this.gui.hwnd, "int", this.DWMWA_USE_IMMERSIVE_DARK_MODE, "int*", 1, "int", 4)
    }
    DarkScrollBars() {
      DllCall("uxtheme\SetWindowTheme", "Ptr", this.rc._control.hwnd, "Str", "DarkMode_Explorer", "Ptr", 0)
    }
    SizeContents() {
      this.gui.GetClientPos(,, &innerWidth, &innerHeight)
      this.rc._control.Move(,, innerWidth - (this.MARGIN * 2), innerHeight - (this.MARGIN * 2))
      this.setScrollBars()
    }
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
    if (this.gui == "") {
      this.loadGui()
    } else {
      this.gui.show()
    }
    if (RichDump.log == "") {
      RichDump.log := this.EMPTY_LOG_MESSAGE
    }
    this.rc.Text := RichDump.log
    SetLogProperties()
    SetGuiSize()
    ScrollToEnd()

    SetLogProperties() {
      Loop parse RichDump.log, "`n", "`r" {
        if (this.log.lineLength <= currentLength := StrLen(A_LoopField)) {
          this.log.lineLength := currentLength
        }
        this.log.lines := A_Index
      }
      this.log.px.x := Min(
        this.CHAR_WIDTH * this.log.lineLength + (this.MARGIN * 3),
        (A_ScreenWidth / 2) - (this.MARGIN * 2)
      )
      this.log.px.y := Min(
        this.LINE_HEIGHT * this.log.lines + (this.MARGIN * 2),
        A_ScreenHeight - (this.MARGIN * 2) - this.TITLE_BAR_HEIGHT - this.SCREEN_OFFSET
      )
    }
    SetGuiSize() {
      this.gui.Move(
        A_ScreenWidth - this.log.px.x + (this.MARGIN * 2) - this.SCREEN_OFFSET,
        A_ScreenHeight - this.log.px.y + (this.MARGIN * 2) - this.SCREEN_OFFSET,
        this.log.px.x + (this.MARGIN * 2),
        this.log.px.y + (this.MARGIN * 2) + this.TITLE_BAR_HEIGHT,
      )
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