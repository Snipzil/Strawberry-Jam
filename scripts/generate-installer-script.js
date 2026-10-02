if (process.platform !== 'win32') {
  process.exit(0);
}

const fs = require('fs');
const path = require('path');

const buildDir = path.join(__dirname, '..', 'build');
const nshScriptPath = path.join(buildDir, 'installer.nsh');

if (!fs.existsSync(buildDir)) {
  fs.mkdirSync(buildDir, { recursive: true });
}

const APP_EXE = 'strawberry-jam.exe';
const GAME_EXE = 'AJ Classic.exe';

// Exit code 0 while the process is still running.
const isRunning = (exe) =>
  `nsExec::Exec \`"$SYSDIR\\cmd.exe" /C tasklist /NH /FI "IMAGENAME eq ${exe}" | "$SYSDIR\\find.exe" /I "${exe}"\``;

// Replaces electron-builder's running-app check. Its default matches every
// process whose path starts with $INSTDIR, which also catches
// strawberry-jam-classic\AJ Classic.exe, and then asks with "is running, click
// OK" and "cannot be closed, retry" dialogs. Here both apps are closed without
// asking (nsExec, so no console windows) and we wait up to ~10s for them to
// exit so their files aren't in use. Also used by the uninstaller.
const nshScriptContent = [
  'RequestExecutionLevel user',
  '',
  '!macro customCheckAppRunning',
  `  nsExec::Exec 'taskkill /F /T /IM "${APP_EXE}"'`,
  '  Pop $0',
  `  nsExec::Exec 'taskkill /F /T /IM "${GAME_EXE}"'`,
  '  Pop $0',
  '  StrCpy $R1 0',
  '  sj_wait_for_exit:',
  `    ${isRunning(APP_EXE)}`,
  '    Pop $0',
  '    StrCmp $0 0 sj_still_running',
  `    ${isRunning(GAME_EXE)}`,
  '    Pop $0',
  '    StrCmp $0 0 sj_still_running sj_closed',
  '  sj_still_running:',
  '    IntOp $R1 $R1 + 1',
  '    IntCmp $R1 40 sj_closed',
  '    Sleep 250',
  '    Goto sj_wait_for_exit',
  '  sj_closed:',
  '!macroend',
  ''
].join('\n');

fs.writeFileSync(nshScriptPath, nshScriptContent);

console.log(`Successfully generated ${nshScriptPath}`);
