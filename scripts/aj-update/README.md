# AJ client auto-updater

The app always serves our own `ajclient.swf`, so whenever Animal Jam ships a
client update (a new "deploy", e.g. 1830) our client goes stale until AJ's
changes are ported in. This tool does that port.

```
npm run aj:check     # is AJ on a newer deploy than our clients? (exit 1 = yes)
npm run aj:update    # port it
```

Needs a JDK and JPEXS FFDec (`C:\Program Files (x86)\FFDec`, or set
`FFDEC_HOME`), plus `git` on PATH (used for `git merge-file`).

## What it does

For each client it keeps the vanilla deploy it was last synced to in
`state.json`. That deploy is the merge base.

1. Reads `deploy_version` from `https://www.animaljam.com/flashvars`.
2. Downloads vanilla `ajclient.swf` for the old and new deploy from
   `ajcontent.akamaized.net/<deploy>/` (cached in `work/vanilla/`, hashes
   pinned in `state.json`).
3. Exports scripts from old vanilla, new vanilla and our client with FFDec
   (cached by SWF hash; one export at a time, single-threaded).
4. For each class, three-way merges with `git merge-file` (base = old
   vanilla, ours = our client, theirs = new vanilla):
   - we never modified it: take AJ's version;
   - already matches: nothing to do;
   - our edits and AJ's in different places: merged;
   - both sides added lines in the same place and one contains the other
     (we ported part of an AJ change by hand earlier): keep the larger side;
   - anything else: a **conflict** for you to resolve.
5. Compiles the result into the SWF with `tool/AjUpdateTool.java` (adds
   classes AJ added; LZMA-compresses the output) and reloads it to check
   every class is there.
6. Installs it, writes merged sources back to `scripts/patches/src`, and
   updates `state.json`.

The two clients:

| target | file | how |
| --- | --- | --- |
| `modded` | `assets/flash/ajclient.swf` | Keeps our SWF and compiles in only the classes AJ changed. Everything else keeps its existing bytecode, so nothing else gets the decompile/recompile treatment (the `RoomManagerWorld` heartbeat freeze came from that). For classes in `scripts/patches/src`, that file is "ours" and gets the merged result. |
| `unmodded` | `assets/flash/options/unmodded-ajclient.swf` | Rebuilt from AJ's fresh SWF plus our merged `SmartFoxClient`, which points the client at the local proxy (`127.0.0.1`, no secure socket). It isn't pure vanilla and can't be: without that hook it can't connect through the app. |

## When it stops

- **Conflicts.** Files land in `work/<target>-<old>-to-<new>/conflicts/` with
  diff3 markers (`<<<<<<< strawberry-jam`, `||||||| aj-<old>`, `=======`,
  `>>>>>>> aj-<new>`). Edit each one into the class you want, remove every
  marker, and run `npm run aj:update` again. A conflict file without markers is
  used exactly as written.
- **Compile errors.** FFDec's compiler rejected a merged class (line numbers
  are printed). Fix the copy in `merged/`, save it to the same path under
  `conflicts/`, and run again.
- **Warnings** are printed and saved in `REPORT.md`. They cover things it
  doesn't port: AJ changing non-script tags (binary data, images), removing a
  class, or changing an unnamed frame script.

## After it succeeds

Test in game. Remember the installed app may own port 7681. Then release as usual:
copy `assets/flash/ajclient.swf` to `options/vX.Y.Z.swf`, set
`LATEST_SWF_FILE` and `PREVIOUS_LATEST_SWF_FILES` in
`src/api/controllers/FilesController.js`, and commit `state.json` and any
changed `scripts/patches/src` files with it. The previous client is saved as
`work/<target>-.../backup-<time>.swf`.

## Options

`node scripts/aj-update/aj-update.js --help` lists them. Useful ones:

- `--target modded|unmodded`: one client only.
- `--no-install`: build into `work/` and change nothing else.
- `--deploy <n>`: port to a specific deploy instead of the live one.
- `--base-swf`, `--ours-swf`, `--ignore-sources`: replay a past port. For
  example, this reproduces the hand-made deploy 1830 port exactly:

  ```
  node scripts/aj-update/aj-update.js --target modded --force --deploy 1830 --no-install ^
    --base-swf assets/flash/options/unmodded-ajclient.swf ^
    --ours-swf assets/flash/options/pre-aj1830-port-backup-20261002-224823.swf --ignore-sources
  ```

## Limits

- The merge base is the vanilla deploy in `state.json`. Differences between
  our client and that deploy count as "our mods", including any older AJ change
  that was never ported. Those stay as they are; they aren't updated.
- Merging is textual on FFDec's decompiled output. A clean merge compiles,
  but it is not proof that the code behaves the same. Still test in game, and
  read the `merged` classes in `REPORT.md` when an update touches gameplay.
