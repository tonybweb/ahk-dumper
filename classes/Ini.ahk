class DumperIni {
  contents := {}
  hasFile := false
  filename := "dumper.ini"

  __New()
  {
    if (! A_IsCompiled) {
      this.filename := StrSplit(A_LineFile, "classes\Ini.ahk")[1] this.filename
    }

    if (this.hasFile := FileExist(this.filename)) {
      sections := StrSplit(IniRead(this.filename), "`n")
      for i, sectionName in sections {
        this.addSection(sectionName)
      }
    }

    defaults := {
      w: width := A_ScreenWidth / 4,
      h: height := A_ScreenHeight / 3,
      x: A_ScreenWidth / 2 - (width / 2),
      y: A_ScreenHeight / 2 - (height / 2),
      stopOnError: 1
    }

    if (this.hasFile) {
      AddMissingDefaults()
    } else {
      SaveDefaults()
    }

    this.scriptName := this.contents.%A_ScriptName%

    SaveDefaults() {
      this.contents := {
        %A_ScriptName%: defaults
      }
      this.save()
    }
    AddMissingDefaults()
    {
      save := false
      if (! this.contents.HasProp(A_ScriptName)) {
        this.contents.%A_ScriptName% := {}
      }
      for propertyName, value in defaults.OwnProps() {
        if (! this.contents.%A_ScriptName%.HasProp(propertyName)) {
          this.contents.%A_ScriptName%.%propertyName% := value
          save := true
        }
      }
      if (save) {
        this.save()
      }
    }
  }

  addSection(sectionName)
  {
    this.contents.%sectionName% := {}

    keysValuePairs := StrSplit(IniRead(this.filename, sectionName), "`n")
    for i, pair in keysValuePairs {
      pair := StrSplit(pair, "=")
      key := pair[1]
      value := pair[2]
      this.contents.%sectionName%.%key% := value
    }
  }

  save()
  {
    for sectionName, section in this.contents.OwnProps() {
      IniDelete(this.filename, sectionName)

      sectionContents := ""
      for key, value in section.OwnProps() {
        sectionContents .= key "=" value "`n"
      }

      if (sectionContents) {
        IniWrite(sectionContents, this.filename, sectionName)
      }
    }
  }
}