#Requires AutoHotkey v2

Array.Prototype.DefineProp("In", {
  Call: (haystack, needle) {
    for (k,v in haystack) {
      if (needle == v) {
        return true
      }
    }
    return false
  }
})
