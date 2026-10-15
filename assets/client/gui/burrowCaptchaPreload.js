"use strict";

const { contextBridge, ipcRenderer } = require("electron");

// For a Burrow server's /captcha page in its window (index.js): hands the
// Turnstile answer back. The page calls window.burrowCaptcha.done(token).
contextBridge.exposeInMainWorld("burrowCaptcha", {
  done: token => ipcRenderer.send("burrowCaptchaDone", String(token)),
});
