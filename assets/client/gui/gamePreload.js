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

// F10 in Flash calls ExternalInterface.call("sjModMenu.toggle"). Returning true hands
// the menu to the host's HTML mod menu; false makes Flash open its classic menu.
let htmlModMenuEnabled = false;
// on a Burrow server, Settings shows Burrow's rows (MySettings in the SWF)
let burrowServer = false;
ipcRenderer.on("modMenuConfig", (event, config) => {
  htmlModMenuEnabled = !!(config && config.html);
  burrowServer = !!(config && config.burrow);
});
const modMenu = {
  toggle: () => {
    if (!htmlModMenuEnabled) return false;
    ipcRenderer.sendToHost("modMenuToggle");
    return true;
  },
  isBurrow: () => burrowServer,
  // Settings' Item Finder and Theme rows open these tabs of the HTML menu
  openTab: (tab) => {
    if (tab !== "burrow-items" && tab !== "burrow") return false;
    ipcRenderer.sendToHost("modMenuOpenTab", tab);
    return true;
  }
};

try {
  contextBridge.exposeInMainWorld("sjModMenuTheme", modMenuTheme);
  contextBridge.exposeInMainWorld("sjModMenu", modMenu);
}
catch (err) {
  window.sjModMenuTheme = modMenuTheme;
  window.sjModMenu = modMenu;
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

