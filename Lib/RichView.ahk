#Include "ColorButton.ahk\ColorButton.ahk"
#Include "RichCode\Highlighter.ahk"
#Include "RichCode\RichCode.ahk"

class RichView
{
  EMPTY_LOG_MESSAGE := ";log empty, use ``dumpGui()`` to output to this window`n`n`n`n`n"

  BUTTONS := {
    FONT_SIZE: 12,
    H: 35,
    W: 90,
  }
  DWMWA_USE_IMMERSIVE_DARK_MODE := 20
  WS_HSCROLL := 0x100000
  WS_VSCROLL := 0x200000

  allowScrollToEnd := true
  gui := ""
  log := {
    lines: 0,
    lineLength: 0,
  }

  rcSettings := {
    TabSize: 2,
    Indent: "  ",
    Font: { Bold: false },
    WordWrap: false,

    UseHighlighter: true,
    HighlightDelay: 200,
    Highlighter: Highlighter,
  }

  __New(theme, ini)
  {
    this.theme := RichThemes.%theme%
    this.ini := ini

    this.rcSettings.Font.Typeface := this.theme.font
    this.rcSettings.Font.Size := this.theme.fontSize
    this.rcSettings.guiMarginColor := this.theme.guiMarginColor
    this.rcSettings.FGColor := this.theme.FGColor
    this.rcSettings.BGColor := this.theme.BGColor
    this.rcSettings.colors := this.theme.colors
  }

  destroy()
  {
    this.rc.__Delete()
    this.rc := ""
    this.gui.destroy()
    this.gui := ""
  }

  load()
  {
    this.gui := Gui("+Resize +AlwaysOnTop +MinSize590x180", "Dumper - " A_ScriptName)
    this.gui.SetFont("s" this.BUTTONS.FONT_SIZE " cFFFFFF")
    this.gui.MarginX := this.gui.MarginY := this.theme.margin
    this.gui.BackColor := this.rcSettings.guiMarginColor

    this.gui.clearBtn := this.gui.AddButton("Section XM W" this.BUTTONS.W  " H" this.BUTTONS.H, "Clear")
    this.gui.clearBtn.SetColor(this.theme.buttons.default.bg, this.theme.buttons.default.fg)
    this.gui.clearBtn.OnEvent("Click", (*) => Clear())

    this.gui.pauseBtn := this.gui.AddButton("WP HP X+" this.theme.margin, "Pause")
    this.gui.pauseBtn.SetColor(this.theme.buttons.danger.bg, this.theme.buttons.danger.fg)
    this.gui.pauseBtn.OnEvent("Click", (*) => this.pauseHandler())

    if (RichDump.errorCapturing) {
      this.gui.stopOnError := this.gui.AddCheckBox(
        "H" this.BUTTONS.H " X+" this.theme.margin " Checked" (this.ini.scriptName.stopOnError ?? "0"),
        "Stop On Error"
      )
      this.gui.stopOnError.OnEvent("Click", (*) => StopOnErrorHandler())
    }

    this.gui.restartBtn := this.gui.AddButton("X+" this.theme.margin " W" this.BUTTONS.W  " H" this.BUTTONS.H, "Restart")
    this.gui.restartBtn.SetColor(this.theme.buttons.default.bg, this.theme.buttons.default.fg)
    this.gui.restartBtn.OnEvent("Click", (*) => Reload())

    this.gui.exitBtn := this.gui.AddButton("WP HP X+" this.theme.margin, "Exit")
    this.gui.exitBtn.SetColor(this.theme.buttons.danger.bg, this.theme.buttons.danger.fg)
    this.gui.exitBtn.OnEvent("Click", (*) => ExitApp())

    RichCode.MenuItems := []
    this.rc := RichCode(this.gui, this.rcSettings, "Section XM W" this.ini.scriptName.w " H" this.ini.scriptName.h)
    DarkScrollBars()
    DarkInactiveState()

    this.gui.OnEvent("Close", (*) => this.destroy())
    this.gui.OnEvent("Escape", (*) => this.destroy())
    this.gui.OnEvent("Size", (*) => PositionContents())

    this.gui.Show("x" A_ScreenWidth " y" A_ScreenHeight " NoActivate")

    Clear()
    {
      RichDump.log := ""
      this.rc.Text := RichDump.log
    }
    StopOnErrorHandler()
    {
      this.ini.scriptName.stopOnError := this.gui.stopOnError.value
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
      this.gui.restartBtn.Move(innerWidth - (this.theme.margin * 2) - (this.BUTTONS.W * 2))
      this.gui.exitBtn.Move(innerWidth - this.theme.margin - this.BUTTONS.W)
      this.rc._control.Move(,, innerWidth - (this.theme.margin * 2), innerHeight - (this.theme.margin * 3) - this.BUTTONS.H)
      this.setScrollBars()
    }
  }

  setScrollBars()
  {
    this.rc._control.GetPos( , , &richWidth, &richHeight)

    textWidth := this.theme.charWidth * this.log.lineLength
    textHeight := this.theme.lineHeight * this.log.lines
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

  show()
  {
    firstShow := 1
    if (this.gui == "") {
      this.load()
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
          this.ini.scriptName.x,
          this.ini.scriptName.y,
          this.ini.scriptName.w,
          this.ini.scriptName.h,
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

  toggle()
  {
    if (this.gui == "") {
      this.show()
    } else {
      this.destroy()
    }
  }
}