# Dumper
An AutoHotkey V2 variable dumping tool for debugging and development.

<img src="Resources\debugConsole.png" alt="Debug Console" width="49%"/><img src="Resources\guiAndSysTray.png" alt="GUI and SysTray" width="49%"/>
<p align="center" width="100%"><img src="Resources\guiButtons.png" alt="GUI with Buttons" width="628"/></p>

## Motivation
In other languages I've grown accustomed to having nicely formatted indenting when debugging my applications. While I could get by with AHK's built-in `OutputDebug` or my editors debugger, I just found myself missing the ease of use of a `dump` or `console.log` type function. I also just really dislike the standard suggestion of "use `MsgBox()` or `ToolTip()`".

## Features
- nice indented formatting for objects
- console output
- string output
- MsgBox output
- Built-in GUI output
  - syntax highlighting
  - error capturing
  - remembers size and position
  - configurable stop on error
  - pause / resume
  - clear log
  - restart / exit app
  - can be auto added to your AHK systray
- recursion protection
- dump and exit app support
- customizable Console and GUI theme support

## Examples
### GUI Output
```
#Requires AutoHotkey v2
#Include <ahk-dumper\RichDumper>

str := "foobar"
dumpGui(str)

>
"foobar"
```
### GUI Output With Error Capturing
```
#Requires AutoHotkey v2
#Include <ahk-dumper\RichDumper_ErrorCapturing>

;Generate an error
Integer("a string")
```
### Console Output
```
#Requires AutoHotkey v2
#Include <ahk-dumper\Dumper>

str := "foobar"
dump(str)

>
"foobar"
```
```
i := 1234
dump(i)

>
1234
```
```
ary := [1, 2, 3]
dump(ary)

>
{
  [1]: 1,
  [2]: 2,
  [3]: 3
}
```
```
aryMap := Map("foo", "bar", "asdf", "jkl;")
dump(aryMap)

>
{
  ["asdf"]: "jkl;",
  ["foo"]: "bar"
}
```
```
obj := ary
obj.helloWorld := {
  foo: "bar",
  bar: [1, 2],
  baz: "asdf",
}
obj.objInObj := obj ;recursion protected
dump(obj)

>
{
  [1]: 1,
  [2]: 2,
  [3]: 3,
  helloWorld: {
    bar: {
      [1]: 1,
      [2]: 2
    },
    baz: "asdf",
    foo: "bar"
  },
  objInObj: *RECURSION PROTECTED*
}
```
### String Output
```
str := dumpString(obj)
MsgBox(str, "obj converted to string output")
```
### MsgBox Output
```
dumpMsgBox(obj)
```
![dumpToMsgBox Screenshot](Resources\dumpToMsgBox.png)
### Dump and Exit App
```
dumpExit("asdf")

>
"asdf"
```
### Multiple Variables at Once
```
dump(str, i, ary, obj)

>
"foobar"
1234

...
```
## How To
### Change Console Theme
You can change the console theme by modifying the `setTheme` section at the top of the `Dumper.ahk` file. Available options are `"dracula"` and `"vsCode"`... or make your own:
```
dump(values*) => Dumper().setTheme("vsCode").Call(values*)
```
### Change GUI Theme
You can change the GUI theme by modifying the `richDumper := RichDump()` line at the top of the `RichDumper.ahk` file. Available options are `"dracula"` and `"vsCode"`... or make your own in the `RichThemes.ahk` file:
```
richDumper := RichDump('vsCode')
```
### Add GUI to SysTray
This isn't necessary if you don't want it, the GUI will automatically open anytime you call `dumpGui()`. However if you want to get back to the GUI log, perhaps after closing it, this can be handy.
```
#Requires AutoHotkey v2
#Include <ahk-dumper\RichDumper>

richDumper.addToSysTray()
```
### See the output in VS Code
You'll need an AutoHotkey debugging extension. zero-plusplus's VS Code extension [[link](https://marketplace.visualstudio.com/items?itemName=zero-plusplus.vscode-autohotkey-debug)] is confirmed to work but others should work as well. Dumper doesn't do anything particuarly special. Any debugger that works with AHK's built-in `OutputDebug`[[link](https://www.autohotkey.com/docs/v2/lib/OutputDebug.htm)] function should work with Dumper.

Once a debugger extension is installed and configured `F5` will run your current `.ahk` file inside of VS Code. Find your "debug console" to see Dumper's output.
### I don't have the Fira Code font, where do I get it?
It's in the Resources\FiraCode font folder. Install it and you should be all set.
### I don't like the Fira Code font, I want to use another font.
That's fine, use whatever font you want but you'll have to adjust the constants at the top of the `RichDumper.ahk` file. If you don't adjust the constants the show/hide scrollbar functionality won't work correctly. Specifically these:
```
  FONT := "Fira Code"
  FONT_SIZE := 14
  CHAR_WIDTH := 11
  LINE_HEIGHT := 31
```
### How should I include Dumper in my script?
There are three ways to include Dumper, choose only 1:
```
#Requires AutoHotkey v2

#Include <ahk-dumper\Dumper> ;minimalist, no GUI support, debug console support only
#Include <ahk-dumper\RichDumper> ;Includes GUI
#Include <ahk-dumper\RichDumper_ErrorCapturing> ;Includes GUI with Error Capturing (recommended)
```