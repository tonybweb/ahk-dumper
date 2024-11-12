#Requires AutoHotkey v2.0

dump(values*) => Dumper(1, values*)
dumpAndExit(values*) => Dumper(1, values*).exit()
dumpToString(value?) => Dumper(2, value?).outputString

class Dumper
{
  INDENT_VALUE := "  "
  MODE_DEFAULT := 1
  MODE_STRING := 2

  mode := 1
  outputString := ""
  protectedPtrs := []

  __New(mode := 1, values*)
  {
    this.mode := mode

    if (values.Length) {
      for value in values {
        this.protectedPtrs := []
        this.dump(value?)
      }
    } else {
      this.dump()
    }
  }

  dump(value?, level := 1)
  {
    if (IsSet(value)) {
      if (IsObject(value)) {
        if(this.isRecursionProtected(value)) {
          this.output("*RECURSION PROTECTED*")
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
    this.output("{")

    itemLength := (HasProp(value, "__Item") && value.Length)
    propCount := ObjOwnPropCount(value)

    if (itemLength) {
      for i, val in value {
        this.output(LB this.indent(level) "[" i "]: ")
        this.dump(val, level+1)

        if (i < itemLength || propCount) {
          this.output(",")
        }
      }
    }

    if (propCount) {
      for prop, val in value.OwnProps() {
        this.output(LB this.indent(level) prop ": ")
        this.dump(val, level+1)

        if (A_Index < propCount) {
          this.output(",")
        }
      }
    }

    if (propCount || itemLength) {
      this.output(LB this.indent(level-1))
    }

    this.output("}")

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
        return '"' value '"'
      case "Integer", "Float":
        return value
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

  output(value)
  {
    switch (this.mode) {
      case this.MODE_DEFAULT:
        OutputDebug(value)
      case this.MODE_STRING:
        this.outputString .= value
    }
  }
}
