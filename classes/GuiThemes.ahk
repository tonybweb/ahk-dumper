class DumperGuiThemes {
  static dracula := {
    charWidth: 11,
    font: "Fira Code",
    fontSize: 14,
    lineHeight: 31,
    margin: 16,

    guiMarginColor: 0x282A36,
    FGColor: 0xFFFFFF,
    BGColor: 0x21222C,
    buttons: {
      default: {
        bg: 0x6272A4,
        fg: 0xFFFFFF,
      },
      success: {
        bg: 0x50FA7B,
        fg: 0x000000,
      },
      danger: {
        bg: 0xFF5050,
        fg: 0xFFFFFF,
      }
    },
    Colors: {
      BG: 0x21222C,
      Comments:     0x6272A4,
      Functions:    0x50FA7B,
      Multiline:    0x7F9F7F,
      Numbers:      0xBD93F9,
      Punctuation:  0xFF79C6,
      Strings:      0xF1FA8C,

      ;Custom:
      Errors:       0xFF79C6,
      Success:      0x50FA7B,
      Danger:       0xFF5050,

      ; AHK
      A_Builtins:   0xBD93F9,
      Commands:     0x8BE9FD,
      Directives:   0xFF79C6,
      Flow:         0xFF79C6,
      KeyNames:     0xCB8DD9,
    }
  }
  static vscode := {
    charWidth: 11,
    font: "Fira Code",
    fontSize: 14,
    lineHeight: 31,
    margin: 16,

    guiMarginColor: 0x1E1E1E,
    FGColor: 0x9CDCFE,
    BGColor: 0x181818,
    buttons: {
      default: {
        bg: 0xDCDCAA,
        fg: 0x000000,
      },
      success: {
        bg: 0x4EC9B0,
        fg: 0x000000,
      },
      danger: {
        bg: 0xCC5050,
        fg: 0xFFFFFF,
      }
    },
    Colors: {
      BG:           0x181818,
      Comments:     0x6A9955,
      Functions:    0xDCDCAA,
      Multiline:    0x7F9F7F,
      Numbers:      0xFFFFFF,
      Punctuation:  0xCCCCCC,
      Strings:      0xD88B4D,

      ;Custom:
      Errors:       0xFF92DF,
      Success:      0x4EC9B0,
      Danger:       0xCC5050,

      ; AHK
      A_Builtins:   0x569cd6,
      Commands:     0x4EC9B0,
      Directives:   0xC586C0,
      Flow:         0xC586C0,
      KeyNames:     0x569cd6,
    }
  }
}
