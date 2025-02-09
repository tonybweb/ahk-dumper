#Requires AutoHotkey v2

class Ini {
  contents := {}
  hasFile := false

  __New(filename) {
    this.filename := filename

    if (this.hasFile := FileExist(this.filename)) {
      sections := StrSplit(IniRead(this.filename), "`n")
      for i, sectionName in sections {
        this.addSection(sectionName)
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

  HasSection(section)
  {
    return HasProp(this.contents, section)
  }
}
