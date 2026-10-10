"use strict";

// The login screen keeps its theme colours as custom properties on its own
// element, and modals mount in #modal-layer beside it, so they can't inherit
// them. Copy the ones the modals use onto the modal host.
(() => {
  const THEME_PROPERTIES = [
    "--theme-primary",
    "--theme-secondary",
    "--theme-button-bg",
    "--theme-button-border",
    "--theme-button-text"
  ];

  window.syncModalTheme = modal => {
    const source = document.getElementById("login-screen");
    if (!source || !modal) return;
    const computed = getComputedStyle(source);
    for (const name of THEME_PROPERTIES) {
      const value = computed.getPropertyValue(name).trim();
      if (value) {
        modal.style.setProperty(name, value);
      } else {
        modal.style.removeProperty(name);
      }
    }
  };
})();
