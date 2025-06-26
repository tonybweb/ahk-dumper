#Requires AutoHotkey v2
#Include "Lib\Ansi.ahk"

dump(values*) => Dumper().setTheme("dracula").Call(values*)
dumpAnsi(values*) => Dumper(3).setTheme("dracula").Call(values*).outputString
dumpExit(values*) => dump(values*).exit()
dumpLoud(values*) => Dumper().setTheme("loud").Call(values*)
dumpMsgBox(values*) => Dumper(2).Call(values*).msgBox()
dumpString(values*) => Dumper(2).Call(values*).outputString
dumpTip(values*) => Dumper(2).Call(values*).toolTip()

class Dumper {
  static RECURSION_NOTE := " * RECURSION PROTECTED * "
  INDENT_VALUE := "  "
  MODE_CONSOLE := 1
  MODE_STRING := 2
  MODE_WITH_ANSI := 3

  ANSI_MODES := [
    this.MODE_CONSOLE,
    this.MODE_WITH_ANSI
  ]

  THEMES := {
    dracula: {
      default: "fgFFFFFF -bg", ;white / default
      string:  "fgF1FA8C -bg", ;yellow / default
      operator: "fgFF79C6 -bg", ;magenta / default
      numeric: "fgBC93DA -bg", ;purple / default
      warning:  "fgFFFFFF bgFF5050" ;white / red
    },
    loud: {
      default: "fgFFFFFF bgEE5050", ;white / default
      string:  "fgFFFF00 bgEE5050", ;yellow / default
      operator: "fg000000 bgEE5050", ;magenta / default
      numeric: "fgCCCCCC bgEE5050", ;purple / default
      warning:  "fgFF0000 bg00FFFF" ;white / red
    },
    vsCode: {
      default: "fg8ED2EB -bg", ;blue / default
      string:  "fgD88B4D -bg", ;orange / default
      operator: "fgE3D804 -bg", ;yellow / default
      numeric: "fgFFFFFF -bg", ;white / default
      warning:  "fgFFFFFF bgFF5050" ;white / red
    }
  }

  mode := this.MODE_CONSOLE
  outputString := ""
  protectedPtrs := []
  theme := {
    default: "",
    string: "",
    operator: "",
    numeric: "",
    warning: ""
  }

  __New(mode := this.MODE_CONSOLE) {
    this.mode := mode

    if (this.contains(this.ANSI_MODES, this.mode)) {
      this.ansi := Ansi()
    }
  }

  Call(values*) {
    if (values.Length) {
      for value in values {
        this.protectedPtrs := []
        this.dump(value?)
      }
    } else {
      this.dump()
    }
    if (this.mode == this.MODE_CONSOLE) {
      this.resetAnsi()
    }

    return this
  }

  dump(value := unset, level := 1) {
    if (IsSet(value)) {
      if (IsObject(value)) {
        if(this.isRecursionProtected(value)) {
          this.output(Dumper.RECURSION_NOTE, this.theme.warning)
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

  dumpObject(value, level := 1) {
    this.protectedPtrs.InsertAt(level, ObjPtr(value))

    LB := "`n"
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

  exit() {
    ExitApp
  }

  formatValue(value) {
    switch(Type(value)) {
      case "String":
        return this.theme.string '"' value '"'
      case "Integer", "Float":
        return this.theme.numeric value
    }
  }

  indent(level) {
    return StrReplace(Format("{:" level "}",""), " ", this.INDENT_VALUE)
  }

  isRecursionProtected(value) {
    return this.contains(this.protectedPtrs, ObjPtr(value))
  }

  msgBox() {
    MsgBox(this.outputString, "dumpMsgBox")
  }

  output(value, color := "") {
    switch (this.mode) {
      case this.MODE_CONSOLE:
        OutputDebug(color value this.theme.default)
      case this.MODE_STRING:
        this.outputString .= value
      case this.MODE_WITH_ANSI:
        this.outputString .= color value this.theme.default
    }
  }

  setTheme(theme := "dracula") {
    this.theme := {
      default: this.ansi.escCode(this.THEMES.%theme%.default),
      string: this.ansi.escCode(this.THEMES.%theme%.string),
      operator: this.ansi.escCode(this.THEMES.%theme%.operator),
      numeric: this.ansi.escCode(this.THEMES.%theme%.numeric),
      warning: this.ansi.escCode(this.THEMES.%theme%.warning)
    }

    return this
  }

  resetAnsi() {
    OutputDebug(this.ansi.escCode("-fg -bg"))
  }

  toolTip() {
    static log := "", endTime := 0, hideDelay := 5000,
      lastX := -1, lastY := -1, lastLog := "", offset := 28

    endTime := A_TickCount + hideDelay
    log := Trim(log "`n" this.outputString, "`n ")
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

  contains(haystack, needle) {
    for (k,v in haystack) {
      if (needle == v) {
        return true
      }
    }
    return false
  }
}
