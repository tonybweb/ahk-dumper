#Requires AutoHotkey v2.0
#Include "Ansi.ahk"

dump(values*) => Dumper().setTheme("dracula").Call(values*)
dumpLoud(values*) => Dumper().setTheme("loud").Call(values*)
dumpAndExit(values*) => dump(values*).exit()
dumpToMsgBox(value?) => Dumper(2).Call(value?).msgBox()
dumpToString(value?) => Dumper(2).Call(value?).outputString

class Dumper
{
  INDENT_VALUE := "  "
  MODE_CONSOLE := 1
  MODE_STRING := 2

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

  __New(mode := this.MODE_CONSOLE)
  {
    this.mode := mode

    if (this.mode == this.MODE_CONSOLE) {
      this.ansi := Ansi()
    }
  }

  Call(values*)
  {
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

  dump(value?, level := 1)
  {
    if (IsSet(value)) {
      if (IsObject(value)) {
        if(this.isRecursionProtected(value)) {
          this.output("*RECURSION PROTECTED*", this.theme.warning)
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

  dumpObject(value, level := 1)
  {
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
        this.dump(val, level+1)

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

  exit()
  {
    ExitApp
  }

  formatValue(value)
  {
    switch(Type(value)) {
      case "String":
        return this.theme.string '"' value '"'
      case "Integer", "Float":
        return this.theme.numeric value
    }
  }

  indent(level)
  {
    return StrReplace(Format("{:" level "}",""), " ", this.INDENT_VALUE)
  }

  isRecursionProtected(value)
  {
    for ptr in this.protectedPtrs {
      if (ptr == ObjPtr(value)) {
        return true
      }
    }
    return false
  }

  msgBox()
  {
    MsgBox(this.outputString, "dumpToMsgBox")
  }

  output(value, color := "")
  {
    switch (this.mode) {
      case this.MODE_CONSOLE:
        OutputDebug(color value this.theme.default)
      case this.MODE_STRING:
        this.outputString .= value
    }
  }

  setTheme(theme := "dracula")
  {
    this.theme := {
      default: this.ansi.escCode(this.THEMES.%theme%.default),
      string: this.ansi.escCode(this.THEMES.%theme%.string),
      operator: this.ansi.escCode(this.THEMES.%theme%.operator),
      numeric: this.ansi.escCode(this.THEMES.%theme%.numeric),
      warning: this.ansi.escCode(this.THEMES.%theme%.warning)
    }

    return this
  }

  resetAnsi()
  {
    OutputDebug(this.ansi.escCode("-fg -bg"))
  }
}
