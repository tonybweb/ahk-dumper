#Requires AutoHotkey v2.0
; https://en.wikipedia.org/wiki/ANSI_escape_code#Control_Sequence_Introducer_commands

class Ansi {
  FG_CODE := 38
  DEFAULT_FG := 39
  BG_CODE := 48
  DEFAULT_BG := 49
  RGB_CODE := 2

  ; ESC[38;2;⟨r⟩;⟨g⟩;⟨b⟩ m Select RGB foreground color
  ; ESC[48;2;⟨r⟩;⟨g⟩;⟨b⟩ m Select RGB background color
  escCode(colors)
  {
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

  csi(n)
  {
    return Chr(27) "[" n "m"
  }

  hex2RGB(hex)
  {
    hex := "0x" hex
    return this.RGB_CODE ";" hex >> 16 & 0xFF ";" hex >> 8 & 0xFF ";" hex & 0xFF
  }
}
