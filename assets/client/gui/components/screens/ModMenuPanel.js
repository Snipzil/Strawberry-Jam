"use strict";

// HTML replacement for the Flash F10 mod menu. All feature state lives in the SWF
// (gui.ModMenuFeatures); this panel reads and changes it through `this.bridge`,
// which GameScreen wires to the ExternalInterface callbacks registered by
// ModMenuFeatures.initBridge(). Runs on the client's Electron 11 / Chrome 87.
(() => {
  const TABS = [
    { id: "mods", title: "Mods" },
    { id: "enhancements", title: "Enhancements" },
    { id: "popups", title: "Popups" },
  ];
  const MASTER_KEY = "modsMasterEnabled";
  const POLL_MS = 3000;
  const PREFS_KEY = "sjHtmlModMenuPrefs";

  const ICON_GLOBE = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3a14 14 0 0 1 0 18a14 14 0 0 1 0-18z"/></svg>`;
  const ICON_USER = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></svg>`;
  const ICON_SEARCH = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>`;
  const ICON_CLOSE = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>`;
  const ICON_OPEN = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 17 17 7"/><path d="M8 7h9v9"/></svg>`;
  const ICON_HOME = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 11 12 4l9 7"/><path d="M5 10v10h14V10"/></svg>`;

  const escapeHtml = (value) => String(value == null ? "" : value)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

  const hasHotkey = (hotkey) => !!hotkey && hotkey !== "N/A";

  const readPrefs = () => {
    try {
      return JSON.parse(localStorage.getItem(PREFS_KEY)) || {};
    }
    catch (err) {
      return {};
    }
  };

  const STYLE = `
    :host {
      position: absolute;
      inset: 0;
      z-index: 200;
      display: none;
      --mm-accent: #e83d52;
      --mm-accent-rgb: 232, 61, 82;
      --mm-on-accent: #ffffff;
      --mm-bg: rgba(16, 16, 19, 0.96);
      --mm-card: rgba(255, 255, 255, 0.035);
      --mm-card-hover: rgba(255, 255, 255, 0.07);
      --mm-line: rgba(255, 255, 255, 0.08);
      --mm-text: #f2f2f5;
      --mm-dim: #a3a3ad;
      --mm-faint: #6c6c78;
      font-family: 'Segoe UI', system-ui, sans-serif;
      color: var(--mm-text);
    }
    :host([open]) { display: block; }
    * { box-sizing: border-box; }

    .backdrop {
      position: absolute;
      inset: 0;
      background: rgba(0, 0, 0, 0.45);
      backdrop-filter: blur(3px);
      opacity: 0;
      transition: opacity 0.18s ease;
    }
    .panel {
      position: absolute;
      left: 50%;
      top: 50%;
      width: min(820px, calc(100% - 32px));
      height: min(560px, calc(100% - 32px));
      transform: translate(-50%, -48%) scale(0.98);
      opacity: 0;
      transition: opacity 0.18s ease, transform 0.22s cubic-bezier(0.34, 1.4, 0.64, 1);
      display: flex;
      flex-direction: column;
      background: var(--mm-bg);
      border: 1px solid var(--mm-line);
      border-radius: 14px;
      box-shadow: 0 24px 60px rgba(0, 0, 0, 0.6), 0 0 0 1px rgba(var(--mm-accent-rgb), 0.12);
      overflow: hidden;
      outline: none;
    }
    .panel::before {
      content: '';
      position: absolute;
      left: 0;
      right: 0;
      top: 0;
      height: 3px;
      background: linear-gradient(90deg, transparent, var(--mm-accent) 20%, var(--mm-accent) 80%, transparent);
      opacity: 0.9;
    }
    :host([visible]) .backdrop { opacity: 1; }
    :host([visible]) .panel { opacity: 1; transform: translate(-50%, -50%) scale(1); }

    header {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 16px 16px 12px 20px;
    }
    .title {
      display: flex;
      flex-direction: column;
      min-width: 0;
      margin-right: auto;
    }
    .title h2 {
      margin: 0;
      font-family: 'CCDigitalDelivery', 'Segoe UI', sans-serif;
      font-size: 20px;
      letter-spacing: 0.02em;
      line-height: 1.1;
    }
    .title .summary {
      margin-top: 3px;
      font-size: 11.5px;
      color: var(--mm-dim);
    }
    .title .summary b { color: var(--mm-accent); font-weight: 600; }

    .search {
      position: relative;
      width: 230px;
    }
    .search svg {
      position: absolute;
      left: 10px;
      top: 50%;
      width: 15px;
      height: 15px;
      transform: translateY(-50%);
      color: var(--mm-faint);
      pointer-events: none;
    }
    .search input {
      width: 100%;
      height: 32px;
      padding: 0 10px 0 32px;
      border-radius: 8px;
      border: 1px solid var(--mm-line);
      background: rgba(255, 255, 255, 0.04);
      color: var(--mm-text);
      font: inherit;
      font-size: 12.5px;
      outline: none;
      transition: border-color 0.15s ease, background 0.15s ease;
    }
    .search input::placeholder { color: var(--mm-faint); }
    .search input:focus {
      border-color: rgba(var(--mm-accent-rgb), 0.7);
      background: rgba(255, 255, 255, 0.06);
    }

    .chip {
      display: inline-flex;
      align-items: center;
      gap: 7px;
      height: 32px;
      padding: 0 12px;
      border-radius: 8px;
      border: 1px solid var(--mm-line);
      background: rgba(255, 255, 255, 0.03);
      color: var(--mm-dim);
      font: inherit;
      font-size: 12px;
      font-weight: 600;
      cursor: pointer;
      white-space: nowrap;
      transition: all 0.15s ease;
    }
    .chip::before {
      content: '';
      width: 7px;
      height: 7px;
      border-radius: 50%;
      border: 1.5px solid currentColor;
    }
    .chip:hover { color: var(--mm-text); background: rgba(255, 255, 255, 0.06); }
    .chip[aria-pressed="true"] {
      color: var(--mm-text);
      border-color: rgba(var(--mm-accent-rgb), 0.8);
      background: rgba(var(--mm-accent-rgb), 0.16);
    }
    .chip[aria-pressed="true"]::before { background: var(--mm-accent); border-color: var(--mm-accent); }

    .icon-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 32px;
      height: 32px;
      border-radius: 8px;
      border: 1px solid var(--mm-line);
      background: rgba(255, 255, 255, 0.03);
      color: var(--mm-dim);
      cursor: pointer;
      transition: all 0.15s ease;
    }
    .icon-btn svg { width: 16px; height: 16px; }
    .icon-btn:hover { color: #fff; background: rgba(232, 61, 82, 0.85); border-color: transparent; }

    nav {
      display: flex;
      gap: 4px;
      padding: 0 16px;
      border-bottom: 1px solid var(--mm-line);
    }
    nav button {
      position: relative;
      display: inline-flex;
      align-items: center;
      gap: 7px;
      padding: 9px 14px 11px;
      border: 0;
      background: none;
      color: var(--mm-dim);
      font: inherit;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      transition: color 0.15s ease;
    }
    nav button:hover { color: var(--mm-text); }
    nav button .count {
      min-width: 20px;
      padding: 1px 6px;
      border-radius: 10px;
      background: rgba(255, 255, 255, 0.07);
      color: var(--mm-dim);
      font-size: 10.5px;
      font-weight: 700;
      text-align: center;
    }
    nav button[aria-selected="true"] { color: var(--mm-text); }
    nav button[aria-selected="true"] .count { background: rgba(var(--mm-accent-rgb), 0.22); color: var(--mm-text); }
    nav button[aria-selected="true"]::after {
      content: '';
      position: absolute;
      left: 10px;
      right: 10px;
      bottom: -1px;
      height: 2px;
      border-radius: 2px;
      background: var(--mm-accent);
    }

    .body {
      flex: 1;
      min-height: 0;
      overflow-y: auto;
      padding: 14px 16px 16px;
    }
    .body::-webkit-scrollbar { width: 10px; }
    .body::-webkit-scrollbar-thumb {
      border: 3px solid transparent;
      border-radius: 10px;
      background: rgba(var(--mm-accent-rgb), 0.55);
      background-clip: padding-box;
    }
    .body::-webkit-scrollbar-thumb:hover { background-color: var(--mm-accent); }

    .grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 8px;
    }
    .wide { grid-column: 1 / -1; }

    .notice {
      padding: 9px 12px;
      border-radius: 9px;
      border: 1px solid rgba(255, 190, 70, 0.3);
      background: rgba(255, 190, 70, 0.08);
      color: #f3d7a1;
      font-size: 12px;
    }

    .card {
      position: relative;
      display: flex;
      align-items: flex-start;
      gap: 12px;
      min-height: 60px;
      padding: 11px 12px;
      border-radius: 10px;
      border: 1px solid transparent;
      background: var(--mm-card);
      cursor: pointer;
      user-select: none;
      transition: background 0.15s ease, border-color 0.15s ease;
    }
    .card:hover { background: var(--mm-card-hover); border-color: rgba(var(--mm-accent-rgb), 0.45); }
    .card.on { background: rgba(var(--mm-accent-rgb), 0.07); }
    .card.on:hover { background: rgba(var(--mm-accent-rgb), 0.12); }
    .card.master {
      border-color: rgba(var(--mm-accent-rgb), 0.3);
      background: linear-gradient(90deg, rgba(var(--mm-accent-rgb), 0.14), rgba(var(--mm-accent-rgb), 0.03));
    }
    .card.busy { pointer-events: none; opacity: 0.7; }
    .card.static { cursor: default; }

    .text { flex: 1; min-width: 0; }
    .label-row {
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .label {
      overflow: hidden;
      font-size: 13px;
      font-weight: 600;
      white-space: nowrap;
      text-overflow: ellipsis;
    }
    .desc {
      display: -webkit-box;
      margin-top: 3px;
      overflow: hidden;
      color: var(--mm-dim);
      font-size: 11.5px;
      line-height: 1.35;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
    }
    kbd {
      flex-shrink: 0;
      margin-left: auto;
      padding: 2px 6px;
      border-radius: 5px;
      border: 1px solid var(--mm-line);
      background: rgba(255, 255, 255, 0.05);
      color: var(--mm-dim);
      font-family: inherit;
      font-size: 10px;
      font-weight: 700;
      white-space: nowrap;
    }

    .switch {
      position: relative;
      flex-shrink: 0;
      width: 36px;
      height: 20px;
      margin-top: 1px;
      border-radius: 10px;
      background: rgba(255, 255, 255, 0.14);
      transition: background 0.18s ease, box-shadow 0.18s ease;
    }
    .switch::after {
      content: '';
      position: absolute;
      left: 3px;
      top: 3px;
      width: 14px;
      height: 14px;
      border-radius: 50%;
      background: #fff;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.35);
      transition: transform 0.2s cubic-bezier(0.34, 1.4, 0.64, 1);
    }
    .on > .switch, .switch.on {
      background: var(--mm-accent);
      box-shadow: 0 0 0 3px rgba(var(--mm-accent-rgb), 0.18);
    }
    .on > .switch::after, .switch.on::after { transform: translateX(16px); }

    .scope {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      width: 24px;
      height: 24px;
      margin: -2px -4px 0 0;
      padding: 0;
      border: 0;
      border-radius: 6px;
      background: none;
      color: var(--mm-faint);
      cursor: pointer;
      transition: all 0.15s ease;
    }
    .scope svg { width: 14px; height: 14px; }
    .scope:hover { color: var(--mm-text); background: rgba(255, 255, 255, 0.08); }
    .scope.global { color: var(--mm-accent); }

    .open-btn {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      flex-shrink: 0;
      height: 28px;
      margin-top: 2px;
      padding: 0 12px;
      border: 0;
      border-radius: 7px;
      background: var(--mm-accent);
      color: var(--mm-on-accent);
      font: inherit;
      font-size: 12px;
      font-weight: 700;
      cursor: pointer;
      transition: filter 0.15s ease, transform 0.15s ease;
    }
    .open-btn svg { width: 13px; height: 13px; }
    .open-btn:hover { filter: brightness(1.12); }
    .open-btn:active { transform: scale(0.96); }
    .popup-meta {
      display: flex;
      flex-direction: column;
      align-items: flex-end;
      gap: 6px;
    }

    .den {
      flex-wrap: wrap;
      align-items: center;
    }
    .den .den-icon {
      display: inline-flex;
      color: var(--mm-accent);
    }
    .den .den-icon svg { width: 18px; height: 18px; }
    .den input {
      width: 220px;
      height: 32px;
      padding: 0 10px;
      border-radius: 8px;
      border: 1px solid var(--mm-line);
      background: rgba(0, 0, 0, 0.25);
      color: var(--mm-text);
      font: inherit;
      font-size: 12.5px;
      outline: none;
      transition: border-color 0.15s ease, opacity 0.15s ease;
    }
    .den input:focus { border-color: rgba(var(--mm-accent-rgb), 0.7); }
    .den input:disabled { opacity: 0.45; }

    .empty, .status {
      padding: 50px 20px;
      color: var(--mm-dim);
      font-size: 13px;
      text-align: center;
    }
    .status button {
      margin-top: 12px;
      padding: 7px 14px;
      border: 1px solid var(--mm-line);
      border-radius: 8px;
      background: rgba(255, 255, 255, 0.05);
      color: var(--mm-text);
      font: inherit;
      cursor: pointer;
    }

    footer {
      display: flex;
      align-items: center;
      gap: 16px;
      padding: 9px 20px;
      border-top: 1px solid var(--mm-line);
      color: var(--mm-faint);
      font-size: 11px;
    }
    footer span { display: inline-flex; align-items: center; gap: 5px; }
    footer svg { width: 13px; height: 13px; }
    footer .global { color: var(--mm-accent); }
    footer .keys { margin-left: auto; }
    footer kbd { margin: 0 2px; }

    .toast {
      position: absolute;
      left: 50%;
      bottom: 48px;
      padding: 8px 14px;
      border-radius: 8px;
      background: rgba(30, 30, 34, 0.98);
      border: 1px solid rgba(232, 61, 82, 0.5);
      color: var(--mm-text);
      font-size: 12px;
      opacity: 0;
      transform: translate(-50%, 6px);
      transition: opacity 0.2s ease, transform 0.2s ease;
      pointer-events: none;
    }
    .toast.show { opacity: 1; transform: translate(-50%, 0); }

    @media (max-width: 640px) {
      .grid { grid-template-columns: minmax(0, 1fr); }
      .search { width: 150px; }
      footer .keys { display: none; }
    }
    @media (prefers-reduced-motion: reduce) {
      .panel, .backdrop, .switch, .switch::after { transition: none; }
    }
  `;

  customElements.define("ajd-mod-menu-panel", class extends HTMLElement {
    constructor() {
      super();
      // GameScreen sets this: { call(method, ...args) => Promise }
      this.bridge = null;
      this._state = null;
      this._busy = new Set();
      this._pollTimer = null;
      this._denSaveTimer = null;

      const prefs = readPrefs();
      this._tab = TABS.some(t => t.id === prefs.tab) ? prefs.tab : "mods";
      this._query = typeof prefs.query === "string" ? prefs.query : "";
      this._enabledOnly = prefs.enabledOnly === true;

      this.attachShadow({ mode: "open" }).innerHTML = `
        <style>${STYLE}</style>
        <div class="backdrop" part="backdrop"></div>
        <div class="panel" role="dialog" aria-label="Mod Menu" tabindex="-1">
          <header>
            <div class="title">
              <h2>Mod Menu</h2>
              <div class="summary"></div>
            </div>
            <label class="search">
              ${ICON_SEARCH}
              <input type="text" placeholder="Search mods…" maxlength="40" spellcheck="false">
            </label>
            <button class="chip enabled-only" type="button" aria-pressed="false">Enabled only</button>
            <button class="icon-btn close" type="button" title="Close (Esc)">${ICON_CLOSE}</button>
          </header>
          <nav role="tablist"></nav>
          <div class="body"></div>
          <footer>
            <span><span class="global">${ICON_GLOBE}</span>All accounts</span>
            <span>${ICON_USER}This account only</span>
            <span class="keys"><kbd>F10</kbd> or <kbd>Esc</kbd> to close · <kbd>Ctrl+F</kbd> search</span>
          </footer>
          <div class="toast"></div>
        </div>
      `;

      const root = this.shadowRoot;
      this._panel = root.querySelector(".panel");
      this._summary = root.querySelector(".summary");
      this._search = root.querySelector(".search input");
      this._enabledChip = root.querySelector(".enabled-only");
      this._nav = root.querySelector("nav");
      this._body = root.querySelector(".body");
      this._toast = root.querySelector(".toast");

      this._search.value = this._query;
      this._enabledChip.setAttribute("aria-pressed", String(this._enabledOnly));

      root.querySelector(".backdrop").addEventListener("mousedown", () => this.close());
      root.querySelector(".close").addEventListener("click", () => this.close());
      this._search.addEventListener("input", () => {
        this._query = this._search.value;
        this._savePrefs();
        this._render();
      });
      this._enabledChip.addEventListener("click", () => {
        this._enabledOnly = !this._enabledOnly;
        this._enabledChip.setAttribute("aria-pressed", String(this._enabledOnly));
        this._savePrefs();
        this._render();
      });
      this._nav.addEventListener("click", (event) => {
        const btn = event.target.closest("button[data-tab]");
        if (!btn) return;
        this._tab = btn.dataset.tab;
        this._savePrefs();
        this._body.scrollTop = 0;
        this._render();
      });
      this._body.addEventListener("click", (event) => this._onBodyClick(event));
      this._body.addEventListener("input", (event) => {
        if (event.target.matches(".den input")) this._queueDenSave();
      });
      this._panel.addEventListener("keydown", (event) => this._onKeyDown(event));
    }

    get isOpen() {
      return this.hasAttribute("open");
    }

    toggle() {
      if (this.isOpen) this.close();
      else this.open();
    }

    open() {
      if (this.isOpen) return;
      this.refreshTheme();
      this.setAttribute("open", "");
      requestAnimationFrame(() => this.setAttribute("visible", ""));
      this._panel.focus();
      this._render();
      this._refresh();
      clearInterval(this._pollTimer);
      // hotkeys and plugins can flip mods while the menu is open
      this._pollTimer = setInterval(() => this._refresh(), POLL_MS);
    }

    close() {
      if (!this.isOpen) return;
      clearInterval(this._pollTimer);
      this._pollTimer = null;
      this._flushDenSave();
      this.removeAttribute("visible");
      this.removeAttribute("open");
      this.dispatchEvent(new CustomEvent("closed"));
    }

    // Derives the accent shades from the launcher theme (--theme-primary on <html>).
    refreshTheme() {
      const raw = getComputedStyle(document.documentElement).getPropertyValue("--theme-primary").trim();
      const match = /^#?([0-9a-f]{6})$/i.exec(raw) || /^#?([0-9a-f]{3})$/i.exec(raw);
      if (!match) return;
      let hex = match[1];
      if (hex.length === 3) hex = hex.split("").map(c => c + c).join("");
      const r = parseInt(hex.slice(0, 2), 16);
      const g = parseInt(hex.slice(2, 4), 16);
      const b = parseInt(hex.slice(4, 6), 16);
      const isLight = r * 0.299 + g * 0.587 + b * 0.114 > 160;
      this.style.setProperty("--mm-accent", `#${hex}`);
      this.style.setProperty("--mm-accent-rgb", `${r}, ${g}, ${b}`);
      this.style.setProperty("--mm-on-accent", isLight ? "#1b1b1f" : "#ffffff");
    }

    async _call(method, ...args) {
      if (!this.bridge) throw new Error("not-ready");
      return this.bridge.call(method, ...args);
    }

    async _refresh() {
      if (this._refreshing || this._busy.size > 0) return;
      this._refreshing = true;
      try {
        const raw = await this._call("sjModMenuGetState");
        const state = typeof raw === "string" ? JSON.parse(raw) : raw;
        if (!state || !Array.isArray(state.toggles)) throw new Error("bad-state");
        const hadState = !!this._state;
        const shapeChanged = !hadState || this._shapeKey(state) !== this._shapeKey(this._state);
        const enabledChanged = hadState && this._enabledKey(state) !== this._enabledKey(this._state);
        this._state = state;
        this._error = null;
        if (!this.isOpen) return;
        if (shapeChanged || (enabledChanged && this._enabledOnly)) this._render();
        else this._syncInPlace();
      }
      catch (err) {
        console.warn("[ModMenu] state refresh failed:", err && err.message);
        if (!this._state) {
          this._error = err && err.message === "not-ready" ? "not-ready" : "failed";
          if (this.isOpen) this._render();
        }
      }
      finally {
        this._refreshing = false;
      }
    }

    _shapeKey(state) {
      return state.toggles.map(t => t.key).join(",") + "|" + state.popups.map(p => p.key).join(",");
    }

    _enabledKey(state) {
      return state.toggles.map(t => (t.enabled ? "1" : "0")).join("");
    }

    _savePrefs() {
      try {
        localStorage.setItem(PREFS_KEY, JSON.stringify({ tab: this._tab, query: this._query, enabledOnly: this._enabledOnly }));
      }
      catch (err) {}
    }

    _matches(item) {
      const query = this._query.trim().toLowerCase();
      if (!query) return true;
      return (item.label + " " + item.desc + " " + (item.hotkey || "")).toLowerCase().indexOf(query) !== -1;
    }

    _denMatches() {
      const query = this._query.trim().toLowerCase();
      return !query || "den on login enter den of a different username target username".indexOf(query) !== -1;
    }

    // Items for a tab with the search / "Enabled only" filters applied.
    _itemsFor(tabId) {
      const state = this._state;
      if (!state) return { all: [], shown: [] };
      if (tabId === "popups") {
        const all = state.popups;
        return { all, shown: all.filter(p => this._matches(p)) };
      }
      const all = state.toggles.filter(t => t.category === tabId);
      return { all, shown: all.filter(t => this._matches(t) && (!this._enabledOnly || t.enabled)) };
    }

    _render() {
      this._renderSummary();
      this._renderTabs();
      if (!this._state) {
        this._body.innerHTML = this._error === "failed"
          ? `<div class="status">Couldn't reach the game's mod menu.<br><button type="button" data-action="retry">Try again</button></div>`
          : `<div class="status">${this._error === "not-ready" ? "Waiting for the game to finish loading…" : "Loading mods…"}</div>`;
        return;
      }
      const { shown } = this._itemsFor(this._tab);
      let html = "";
      if (this._tab === "popups") {
        html = shown.map(p => this._popupCard(p)).join("");
      }
      else {
        const master = this._tab === "mods" ? shown.find(t => t.key === MASTER_KEY) : null;
        const masterState = this._state.toggles.find(t => t.key === MASTER_KEY);
        if (masterState && !masterState.enabled) {
          html += `<div class="notice wide">“Enable All Mods” is off, so mods won't run until you turn it back on.</div>`;
        }
        if (master) html += this._toggleCard(master, true);
        html += shown.filter(t => t !== master).map(t => this._toggleCard(t, false)).join("");
        if (this._tab === "mods" && this._denMatches() && (!this._enabledOnly || this._state.den.enabled)) {
          html += this._denCard();
        }
      }
      if (!html || /^<div class="notice/.test(html) && !/class="card/.test(html)) {
        const reason = this._query.trim()
          ? `No mods match “${escapeHtml(this._query.trim())}”.`
          : this._enabledOnly ? "Nothing in this tab is enabled." : "Nothing here yet.";
        html += `<div class="empty wide">${reason}</div>`;
      }
      const scrollTop = this._body.scrollTop;
      this._body.innerHTML = `<div class="grid">${html}</div>`;
      this._body.scrollTop = scrollTop;
    }

    _renderSummary() {
      if (!this._state) {
        this._summary.textContent = "";
        return;
      }
      const toggles = this._state.toggles.filter(t => t.key !== MASTER_KEY);
      const on = toggles.filter(t => t.enabled).length;
      this._summary.innerHTML = `<b>${on}</b> of ${toggles.length} mods enabled`;
    }

    _renderTabs() {
      const filtered = !!this._query.trim() || this._enabledOnly;
      this._nav.innerHTML = TABS.map(tab => {
        const { all, shown } = this._itemsFor(tab.id);
        let count = "";
        if (this._state) {
          const showRatio = filtered && (tab.id !== "popups" || this._query.trim());
          count = `<span class="count">${showRatio ? `${shown.length}/${all.length}` : all.length}</span>`;
        }
        const selected = tab.id === this._tab;
        return `<button type="button" role="tab" data-tab="${tab.id}" aria-selected="${selected}">${tab.title}${count}</button>`;
      }).join("");
    }

    _toggleCard(t, isMaster) {
      const scopeTitle = t.global ? "Applies to all accounts (click for this account only)" : "Applies to this account only (click for all accounts)";
      return `
        <div class="card${t.enabled ? " on" : ""}${isMaster ? " master wide" : ""}" data-key="${escapeHtml(t.key)}" role="switch" aria-checked="${t.enabled}" title="${escapeHtml(t.desc)}">
          <div class="switch"></div>
          <div class="text">
            <div class="label-row">
              <span class="label">${escapeHtml(t.label)}</span>
              ${hasHotkey(t.hotkey) ? `<kbd>${escapeHtml(t.hotkey)}</kbd>` : ""}
            </div>
            <div class="desc">${escapeHtml(t.desc)}</div>
          </div>
          <button type="button" class="scope${t.global ? " global" : ""}" data-scope="${escapeHtml(t.key)}" title="${scopeTitle}">${t.global ? ICON_GLOBE : ICON_USER}</button>
        </div>`;
    }

    _popupCard(p) {
      return `
        <div class="card static" data-popup="${escapeHtml(p.action)}" title="${escapeHtml(p.desc)}">
          <div class="text">
            <div class="label-row"><span class="label">${escapeHtml(p.label)}</span></div>
            <div class="desc">${escapeHtml(p.desc)}</div>
          </div>
          <div class="popup-meta">
            <button type="button" class="open-btn" data-open="${escapeHtml(p.action)}">Open ${ICON_OPEN}</button>
            ${hasHotkey(p.hotkey) ? `<kbd>${escapeHtml(p.hotkey)}</kbd>` : ""}
          </div>
        </div>`;
    }

    _denCard() {
      const den = this._state.den || { enabled: false, username: "" };
      return `
        <div class="card static den wide${den.enabled ? " on" : ""}" data-den>
          <div class="switch${den.enabled ? " on" : ""}" data-den-toggle role="switch" aria-checked="${!!den.enabled}" style="cursor:pointer"></div>
          <span class="den-icon">${ICON_HOME}</span>
          <div class="text">
            <div class="label-row"><span class="label">Den on Login</span></div>
            <div class="desc">Enter the den of a different username when you log in</div>
          </div>
          <input type="text" placeholder="Target username" maxlength="30" spellcheck="false" value="${escapeHtml(den.username || "")}"${den.enabled ? "" : " disabled"}>
        </div>`;
    }

    // Updates switches and scope icons without rebuilding, so hover and focus survive polling.
    _syncInPlace() {
      this._renderSummary();
      this._renderTabs();
      for (const t of this._state.toggles) {
        const card = this._body.querySelector(`.card[data-key="${CSS.escape(t.key)}"]`);
        if (!card || this._busy.has(t.key)) continue;
        card.classList.toggle("on", !!t.enabled);
        card.setAttribute("aria-checked", String(!!t.enabled));
        const scope = card.querySelector(".scope");
        if (scope && scope.classList.contains("global") !== !!t.global) {
          scope.classList.toggle("global", !!t.global);
          scope.innerHTML = t.global ? ICON_GLOBE : ICON_USER;
        }
      }
      const denCard = this._body.querySelector(".card[data-den]");
      if (denCard && !this._denSaveTimer && !this._busy.has("den")) {
        const den = this._state.den || {};
        const input = denCard.querySelector("input");
        denCard.classList.toggle("on", !!den.enabled);
        denCard.querySelector(".switch").classList.toggle("on", !!den.enabled);
        input.disabled = !den.enabled;
        if (this.shadowRoot.activeElement !== input) input.value = den.username || "";
      }
      const masterState = this._state.toggles.find(t => t.key === MASTER_KEY);
      const hasNotice = !!this._body.querySelector(".notice");
      if (masterState && hasNotice === !!masterState.enabled) this._render();
    }

    _onBodyClick(event) {
      if (event.target.closest("[data-action='retry']")) {
        this._error = null;
        this._render();
        this._refresh();
        return;
      }
      const scopeBtn = event.target.closest("[data-scope]");
      if (scopeBtn) {
        event.stopPropagation();
        this._setScope(scopeBtn.dataset.scope);
        return;
      }
      const openBtn = event.target.closest("[data-open]");
      if (openBtn) {
        this._openPopup(openBtn.dataset.open);
        return;
      }
      if (event.target.closest("[data-den-toggle]")) {
        this._toggleDen();
        return;
      }
      const card = event.target.closest(".card[data-key]");
      if (card) this._toggle(card.dataset.key);
    }

    async _toggle(key) {
      const item = this._state && this._state.toggles.find(t => t.key === key);
      if (!item || this._busy.has(key)) return;
      const next = !item.enabled;
      const card = this._body.querySelector(`.card[data-key="${CSS.escape(key)}"]`);
      this._busy.add(key);
      item.enabled = next;
      if (card) {
        card.classList.toggle("on", next);
        card.setAttribute("aria-checked", String(next));
      }
      try {
        item.enabled = !!(await this._call("sjModMenuSetToggle", key, next));
      }
      catch (err) {
        item.enabled = !next;
        this._showToast("Couldn't change that mod. Is the game still running?");
      }
      finally {
        this._busy.delete(key);
      }
      if (this._enabledOnly || key === MASTER_KEY) this._render();
      else this._syncInPlace();
    }

    async _setScope(key) {
      const item = this._state && this._state.toggles.find(t => t.key === key);
      if (!item || this._busy.has(key)) return;
      this._busy.add(key);
      try {
        item.global = !!(await this._call("sjModMenuSetScope", key, !item.global));
      }
      catch (err) {
        this._showToast("Couldn't change where that mod applies.");
      }
      finally {
        this._busy.delete(key);
      }
      this._syncInPlace();
    }

    async _toggleDen() {
      if (!this._state || this._busy.has("den")) return;
      const input = this._body.querySelector(".den input");
      const den = this._state.den || {};
      await this._saveDen(!den.enabled, input ? input.value : den.username);
      const denInput = this._body.querySelector(".den input");
      if (denInput && this._state.den.enabled) denInput.focus();
    }

    _queueDenSave() {
      clearTimeout(this._denSaveTimer);
      this._denSaveTimer = setTimeout(() => this._flushDenSave(), 400);
    }

    _flushDenSave() {
      if (!this._denSaveTimer) return;
      clearTimeout(this._denSaveTimer);
      this._denSaveTimer = null;
      const input = this._body.querySelector(".den input");
      if (input && this._state) this._saveDen(!!this._state.den.enabled, input.value.trim());
    }

    async _saveDen(enabled, username) {
      this._busy.add("den");
      try {
        const den = await this._call("sjModMenuSetDenLogin", enabled, username || "");
        this._state.den = den || { enabled, username };
      }
      catch (err) {
        this._showToast("Couldn't save Den on Login.");
      }
      finally {
        this._busy.delete("den");
      }
      this._syncInPlace();
    }

    async _openPopup(action) {
      try {
        await this._call("sjModMenuOpenPopup", action);
        this.close();
      }
      catch (err) {
        this._showToast("Couldn't open that popup. Is the game still running?");
      }
    }

    _showToast(message) {
      this._toast.textContent = message;
      this._toast.classList.add("show");
      clearTimeout(this._toastTimer);
      this._toastTimer = setTimeout(() => this._toast.classList.remove("show"), 2600);
    }

    _onKeyDown(event) {
      if (event.key === "Escape" || event.key === "F10") {
        event.preventDefault();
        if (event.key === "Escape" && this.shadowRoot.activeElement === this._search && this._search.value) {
          this._search.value = "";
          this._query = "";
          this._savePrefs();
          this._render();
          return;
        }
        this.close();
        return;
      }
      if ((event.ctrlKey && event.key.toLowerCase() === "f") || (event.key === "/" && !this._isTyping())) {
        event.preventDefault();
        this._search.focus();
        this._search.select();
        return;
      }
      if (event.ctrlKey && (event.key === "Tab" || event.key === "PageDown" || event.key === "PageUp")) {
        event.preventDefault();
        const step = event.shiftKey || event.key === "PageUp" ? -1 : 1;
        const index = TABS.findIndex(t => t.id === this._tab);
        this._tab = TABS[(index + step + TABS.length) % TABS.length].id;
        this._savePrefs();
        this._body.scrollTop = 0;
        this._render();
      }
    }

    _isTyping() {
      const active = this.shadowRoot.activeElement;
      return !!active && active.tagName === "INPUT";
    }
  });
})();
