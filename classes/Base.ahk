class DumperBase {
  static DEFAULT_THEME := "dracula", ;dracula, vscode, loud, or make your own
    INDENT_VALUE := "  ",
    RECURSION_NOTE := " * RECURSION PROTECTED * "

  static WM_EXITSIZEMOVE := 0x0232

  static outputString := "",
    protectedPtrs := []

  static Call(values*) {
    if (values.Length) {
      for value in values {
        this.protectedPtrs := []
        this.dump(value?)
      }
    } else {
      this.dump()
    }
    if (this.mode.isConsole()) {
      this.ansi.reset()
    }

    return this
  }

  class ansi {
    ; https://en.wikipedia.org/wiki/ANSI_escape_code#Control_Sequence_Introducer_commands
    static FG_CODE := 38,
      DEFAULT_FG := 39,
      BG_CODE := 48,
      DEFAULT_BG := 49,
      RGB_CODE := 2

    ; ESC[38;2;⟨r⟩;⟨g⟩;⟨b⟩ m Select RGB foreground color
    ; ESC[48;2;⟨r⟩;⟨g⟩;⟨b⟩ m Select RGB background color
    static escCode(colors) {
      code .= ""
      loop parse, colors, " " {
        switch (A_LoopField) {
          case "-fg": code .= this.csi(this.DEFAULT_FG)
          case "-bg": code .= this.csi(this.DEFAULT_BG)
          default:
            if RegExMatch(A_LoopField, "i)^fg([0-9A-F]{6})$", &match) {
              code .= StrReplace(A_LoopField, match[0],
                this.csi(this.FG_CODE ";" this.hex2RGB(match[1])
              ))
            } else if RegExMatch(A_LoopField, "i)^bg([0-9A-F]{6})$", &match) {
              code .= StrReplace(A_LoopField, match[0],
                this.csi(this.BG_CODE ";" this.hex2RGB(match[1])
              ))
            }
        }
      }
      return code
    }

    static csi(n) {
      return Chr(27) "[" n "m"
    }

    static hex2RGB(hex) {
      hex := "0x" hex
      return this.RGB_CODE ";" hex >> 16 & 0xFF ";" hex >> 8 & 0xFF ";" hex & 0xFF
    }

    static reset() {
      OutputDebug(this.escCode("-fg -bg"))
    }
  }

  class mode {
    static MODE_CONSOLE := 1,
      MODE_STRING := 2

    static mode := 0

    static __New() {
      this.mode := this.MODE_CONSOLE
    }
    static console() {
      this.__New()
    }
    static string() {
      this.mode := this.MODE_STRING
    }
    static isConsole() {
      return this.mode == this.MODE_CONSOLE
    }
    static isString() {
      return this.mode == this.MODE_STRING
    }
  }

  class theme {
    static THEMES := {
      dracula: {
        default: Dump.ansi.escCode("fgFFFFFF -bg"), ;white / default
        string:  Dump.ansi.escCode("fgF1FA8C -bg"), ;yellow / default
        operator: Dump.ansi.escCode("fgFF79C6 -bg"), ;magenta / default
        numeric: Dump.ansi.escCode("fgBC93DA -bg"), ;purple / default
        warning:  Dump.ansi.escCode("fgFFFFFF bgFF5050") ;white / red
      },
      loud: {
        default: Dump.ansi.escCode("fgFFFFFF bgEE5050"), ;white / default
        string:  Dump.ansi.escCode("fgFFFF00 bgEE5050"), ;yellow / default
        operator: Dump.ansi.escCode("fg000000 bgEE5050"), ;magenta / default
        numeric: Dump.ansi.escCode("fgCCCCCC bgEE5050"), ;purple / default
        warning:  Dump.ansi.escCode("fgFF0000 bg00FFFF") ;white / red
      },
      vsCode: {
        default: Dump.ansi.escCode("fg8ED2EB -bg"), ;blue / default
        string:  Dump.ansi.escCode("fgD88B4D -bg"), ;orange / default
        operator: Dump.ansi.escCode("fgE3D804 -bg"), ;yellow / default
        numeric: Dump.ansi.escCode("fgFFFFFF -bg"), ;white / default
        warning:  Dump.ansi.escCode("fgFFFFFF bgFF5050") ;white / red
      }
    }

    static theme := ""

    static default => Dump.mode.isConsole() ? this.THEMES.%this.theme%.default : ""
    static string => Dump.mode.isConsole() ? this.THEMES.%this.theme%.string : ""
    static operator => Dump.mode.isConsole() ? this.THEMES.%this.theme%.operator : ""
    static numeric => Dump.mode.isConsole() ? this.THEMES.%this.theme%.numeric : ""
    static warning => Dump.mode.isConsole() ? this.THEMES.%this.theme%.warning : ""

    static __New() {
      this.setTheme(Dump.CONSOLE_THEME)
    }

    static setTheme(theme) {
      this.theme := theme
    }
  }

  static dump(value := unset, level := 1) {
    if (IsSet(value)) {
      if (value is VarRef) {
        value := %value%
      }
      if (IsObject(value)) {
        if(this.isRecursionProtected(value)) {
          this.output(this.RECURSION_NOTE, this.theme.warning)
        } else if (Type(value) == "ComObject" || Type(value) == "ComValue") {
          this.output(" * " Type(value) " * ", this.theme.warning)
        } else {
          this.dumpObject(value, level)
        }
      } else {
        this.output(this.formatValue(value))
      }
    } else {
      this.output("unset")
    }

    if (level == 1) {
      this.output("`n")
    }
  }

  static dumpObject(value, level := 1) {
    static LB := "`n"

    this.protectedPtrs.InsertAt(level, ObjPtr(value))

    this.output("{", this.theme.operator)

    itemLength := (HasProp(value, "__Item") && HasProp(value, "Length")) ? value.Length : 0
    mapCount := (HasProp(value, "__Enum") && HasProp(value, "Count")) ? value.Count : 0
    propCount := ObjOwnPropCount(value)

    if (itemLength || mapCount) {
      for key, val in value {
        if (itemLength) {
          key := this.theme.numeric key this.theme.default
        } else {
          key := this.theme.string '"' key '"' this.theme.default
        }

        this.output(
          LB this.indent(level)
          "[" key "]"
          this.theme.operator ": "
        )
        this.dump(val ?? unset, level+1)

        if (A_Index < itemLength || A_Index < mapCount || propCount) {
          this.output(",")
        }
      }
    }

    if (propCount) {
      for prop, val in value.OwnProps() {
        this.output(LB this.indent(level) prop this.theme.operator ": ",)
        this.dump(val, level+1)

        if (A_Index < propCount) {
          this.output(",")
        }
      }
    }

    if (itemLength || mapCount || propCount) {
      this.output(LB this.indent(level-1))
    }

    this.output("}", this.theme.operator)

    if (level > 1) {
      this.protectedPtrs.RemoveAt(level)
    }
  }

  static exit() {
    ExitApp()
  }

  static formatValue(value) {
    switch(Type(value)) {
      case "String":
        return this.theme.string '"' value '"'
      case "Integer", "Float":
        return this.theme.numeric value
    }
  }

  static indent(level) {
    return StrReplace(Format("{:" level "}",""), " ", this.INDENT_VALUE)
  }

  static isRecursionProtected(value) {
    return this.contains(this.protectedPtrs, ObjPtr(value))
  }

  static loud(values*) {
    this.theme.setTheme("loud")
    this.Call(values*)
    this.theme.setTheme(this.DEFAULT_THEME)

    return this
  }

  static msgBox(values*) {
    MsgBox(this.string(values*), "dumpMsgBox")
    return this
  }

  static output(value, color := "") {
    if (this.mode.isConsole()) {
      OutputDebug(color value this.theme.default)
    } else {
      this.outputString .= value
    }
  }

  static string(values*) {
    this.mode.string()
    this.Call(values*)
    this.mode.console()
    str := this.outputString
    this.outputString := ""

    return str
  }

  static tip(values*) {
    static log := "", endTime := 0, hideDelay := 5000,
      lastX := -1, lastY := -1, lastLog := "", offset := 28

    log := Trim(lastLog "`n" this.string(values*), "`n ")

    endTime := A_TickCount + hideDelay
    SetTimer(Update, 15)

    Update() {
      if (A_TickCount >= endTime) {
        SetTimer(, 0)
        log := "", lastX := -1, lastY := -1, lastLog := ""
        ToolTip()
        return
      }
      MouseGetPos(&x, &y), x += offset, y += offset
      if (lastX != x || lastY != y || lastLog != log) {
        ToolTip(log,x,y)
        lastX := x, lastY := y, lastLog := log
      }
    }
  }

  static exe(callback, iterations) {
    start := A_TickCount
    Loop iterations {
      callback()
    }
    return "execution time" (callback.name ? " — " callback.name : "") ": " (A_TickCount - start)
  }

  static exeTime(callback, iterations := 1) {
    this.dump(this.exe(callback, iterations))
  }

  static contains(haystack, needle) {
    for (k,v in haystack) {
      if (needle == v) {
        return true
      }
    }
    return false
  }
}
