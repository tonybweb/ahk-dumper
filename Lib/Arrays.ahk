#Requires AutoHotkey v2

Array.Prototype.DefineProp("Contains", {
  Call: (haystack, needle) {
    for (k,v in haystack) {
      if (needle == v) {
        return true
      }
    }
    return false
  }
})
