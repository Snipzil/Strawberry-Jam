# In-game Mod Menu (F10) sources

The F10 Mod Menu is ActionScript compiled into `assets/flash/ajclient.swf`
(package `gui`, classes `ModMenu*`). This folder keeps the editable sources for
the UI classes so they can be rebuilt without decompiling.

- `src/` — the five UI classes. `ModMenuFeatures` (feature list, persistence,
  toggle handlers) is intentionally not here; it is left untouched in the SWF.
- `tool/ModMenuTool.java` — replaces every `gui.ModMenu*` script pack in the SWF
  (the SWF contains stale duplicate definitions; all of them get replaced) using
  the JPEXS FFDec library compiler.
- `tool/SwfCompress.java` — re-applies LZMA compression.

## Rebuild (Windows, JDK + JPEXS Free Flash Decompiler installed)

```
set CLASSPATH=C:\Program Files (x86)\FFDec\lib\*;C:\Program Files (x86)\FFDec\ffdec.jar;.
cd scripts\modmenu\tool
javac ModMenuTool.java SwfCompress.java
"C:\Program Files (x86)\FFDec\ffdec-cli.exe" -decompress ..\..\..\assets\flash\ajclient.swf raw.swf
java -Xmx1600m ModMenuTool replace raw.swf new-raw.swf ..\src
java -Xmx1600m SwfCompress new-raw.swf ..\..\..\assets\flash\ajclient.swf
```

`ModMenuTool dump <swf> <outdir>` exports every ModMenu pack (one folder per
script index) for inspection.

`ModMenuTool prune` exists but does not work: FFDec's script delete flag is not
honoured on save, so the stale duplicate packs (scripts 1039, 1048, 1056)
remain. The player uses the first definition (437 / 1046 / 81); `replace`
overwrites every copy, so the duplicates never carry old code.

UI preferences (search text, "Enabled only", last tab) persist in the Flash
SharedObject `sjModMenuUi`.

Rollback: `assets/flash/options/v5.2.0.swf` is the previous client with the old
menu; copy it over `assets/flash/ajclient.swf`.
