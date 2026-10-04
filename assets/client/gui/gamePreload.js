"use strict";

const { ipcRenderer, contextBridge } = require("electron");

const sendWhitelist = new Set()
  .add("initialized")
  .add("printImage")
  .add("reloadGame")
  .add("reportError")
  .add("signupCompleted");

// The F10 mod menu (Flash) reads the launcher theme color synchronously via
// ExternalInterface.call("sjModMenuTheme.get"); the host pushes it on load and on change.
let modMenuThemeColor = "";
ipcRenderer.on("modMenuTheme", (event, color) => {
  modMenuThemeColor = typeof color === "string" ? color : "";
});
const modMenuTheme = { get: () => modMenuThemeColor };
try {
  contextBridge.exposeInMainWorld("sjModMenuTheme", modMenuTheme);
}
catch (err) {
  window.sjModMenuTheme = modMenuTheme;
}

const receiveWhitelist = new Set()
  .add("flashVarsReady")
  .add("removed");

contextBridge.exposeInMainWorld(
  "ipc", {
    sendToHost: (channel, ...args) => {
      if (sendWhitelist.has(channel)) {
        ipcRenderer.sendToHost(channel, ...args);
      }
    },
    on: (channel, listener) => {
      if (receiveWhitelist.has(channel)) {
        ipcRenderer.on(channel, listener);
      }
    }
  }
);

