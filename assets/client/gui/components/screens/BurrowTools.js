"use strict";

// The mod menu's Burrow tab on a Burrow server: how the server is doing, the
// lands' seasonal looks, and saved outfits and den layouts, all through the
// server's own calls (made by the main process, burrowItems.js). Runs on
// Chrome 87.
(() => {
  // the server's Theme list (its config.js `themes`, in the order its own
  // client shows them). An unknown one is refused by the server.
  const THEMES = [
    ["halloween", "Halloween"], ["fall", "Fall"], ["jamaalidays", "Jamaalidays"], ["winter", "Winter"],
    ["friendship", "Friendship"], ["lucky", "Lucky Day"], ["spring", "Spring"], ["summer", "Summer"],
    ["halloween2025", "Halloween 2025"], ["fall2025", "Fall 2025"], ["summer2025", "Summer 2025"],
    ["lucky2025", "Lucky Day 2025"], ["summer2024", "Summer 2024"], ["spring2024", "Spring 2024"],
    ["lucky2024", "Lucky Day 2024"], ["jamaalidays2022", "Jamaalidays 2022"], ["fall2022", "Fall 2022"],
    ["freedom2021", "Freedom Day 2021"], ["jamaalidays2020", "Jamaalidays 2020"], ["spring2020", "Spring 2020"],
    ["jamaalidays2018", "Jamaalidays 2018"], ["summer2018", "Summer 2018"], ["lucky2018", "Lucky Day 2018"],
    ["friendship2018", "Friendship 2018"], ["halloween2013", "Halloween 2013"],
  ];
  const NAME = /^[a-z0-9]{1,20}$/;

  const escapeHtml = (value) => String(value == null ? "" : value)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

  const formatUptime = seconds => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return days ? `${days}d ${hours}h` : hours ? `${hours}h ${minutes}m` : `${minutes}m`;
  };

  const STYLE = `
    .bt { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 10px; }
    .bt-card {
      display: flex;
      flex-direction: column;
      gap: 9px;
      padding: 12px;
      border-radius: 10px;
      background: var(--mm-card);
      border: 1px solid transparent;
    }
    .bt-card.wide { grid-column: 1 / -1; }
    .bt-head { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
    .bt-head h3 { margin: 0; font-size: 13px; font-weight: 700; }
    .bt-sub { color: var(--mm-faint); font-size: 11.5px; line-height: 1.4; }
    .bt-stats { display: flex; gap: 18px; }
    .bt-stat b { display: block; font-size: 20px; color: var(--mm-text); }
    .bt-stat span { color: var(--mm-faint); font-size: 11px; }
    .bt-chips { display: flex; flex-wrap: wrap; gap: 6px; }
    .bt-chip, .bt-btn {
      padding: 5px 11px;
      border-radius: 8px;
      border: 1px solid var(--mm-line);
      background: rgba(255, 255, 255, 0.04);
      color: var(--mm-text);
      font: inherit;
      font-size: 12px;
      cursor: pointer;
      transition: background 0.15s ease, border-color 0.15s ease;
    }
    .bt-chip:hover, .bt-btn:hover { background: rgba(var(--mm-accent-rgb), 0.16); border-color: rgba(var(--mm-accent-rgb), 0.55); }
    .bt-chip.on { background: rgba(var(--mm-accent-rgb), 0.22); border-color: var(--mm-accent); }
    .bt-btn.primary { background: var(--mm-accent); border-color: transparent; color: var(--mm-on-accent); font-weight: 600; }
    .bt-btn:disabled, .bt-chip:disabled { opacity: 0.5; cursor: default; }
    .bt-row { display: flex; gap: 6px; }
    .bt-row input {
      flex: 1;
      min-width: 0;
      height: 30px;
      padding: 0 10px;
      border-radius: 8px;
      border: 1px solid var(--mm-line);
      background: rgba(0, 0, 0, 0.25);
      color: var(--mm-text);
      font: inherit;
      font-size: 12px;
      outline: none;
    }
    .bt-row input:focus { border-color: rgba(var(--mm-accent-rgb), 0.7); }
    .bt-empty { color: var(--mm-faint); font-size: 12px; }
    .bt-msg { min-height: 15px; font-size: 11.5px; color: var(--mm-dim); }
    .bt-msg.ok { color: #4ade80; }
    .bt-msg.err { color: #f87171; }
    .bt-links { display: flex; gap: 14px; font-size: 12px; }
    .bt-links a { color: var(--mm-accent); cursor: pointer; text-decoration: none; }
    .bt-links a:hover { text-decoration: underline; }
  `;

  window.BurrowTools = class {
    constructor(panel) {
      this.panel = panel;
      this.status = null; // {online, uptimeSeconds} | {error}
      this.saved = null; // {outfits, layouts} | {error}
      this.theme = null; // the last one picked here
      this.messages = {}; // card -> {text, kind}
      this.busy = false;

      const style = document.createElement("style");
      style.textContent = STYLE;
      panel.shadowRoot.appendChild(style);
    }

    // no search box on this tab
    get placeholder() {
      return "";
    }

    summary() {
      const server = globals.burrowServer ? new URL(globals.burrowServer).host : "";
      return server ? `Playing on <b>${escapeHtml(server)}</b>` : "";
    }

    activate() {
      this.load();
    }

    async load() {
      const who = { username: globals.currentUser, token: globals.authToken };
      const [status, saved] = await Promise.all([
        window.ipc.invoke("burrow-status").catch(err => ({ error: err.message })),
        window.ipc.invoke("burrow-saved", who).catch(err => ({ error: err.message })),
      ]);
      this.status = status;
      this.saved = saved;
      this.panel._render();
    }

    render(body) {
      body.classList.remove("bif-body");
      const status = this.status;
      const statusHtml = !status ? `<div class="bt-sub">Checking…</div>`
        : status.error ? `<div class="bt-sub">${escapeHtml(status.error)}</div>`
        : `<div class="bt-stats">
            <div class="bt-stat"><b>${status.online}</b><span>playing now</span></div>
            <div class="bt-stat"><b>${formatUptime(status.uptimeSeconds)}</b><span>server up</span></div>
          </div>`;

      const themes = THEMES.map(([id, label]) =>
        `<button type="button" class="bt-chip${this.theme === id ? " on" : ""}" data-theme="${id}" ${this.busy ? "disabled" : ""}>${escapeHtml(label)}</button>`).join("");

      const list = (names, kind) => {
        if (!this.saved) return `<div class="bt-empty">Loading…</div>`;
        if (this.saved.error) return `<div class="bt-empty">${escapeHtml(this.saved.error)}</div>`;
        if (!names.length) return `<div class="bt-empty">None saved yet.</div>`;
        const verb = kind === "outfit" ? "wear" : "load";
        return `<div class="bt-chips">${names.map(name =>
          `<button type="button" class="bt-chip" data-run="!${kind} ${verb} ${escapeHtml(name)}" data-card="${kind}" ${this.busy ? "disabled" : ""}>${escapeHtml(name)}</button>`).join("")}</div>`;
      };
      const msg = card => {
        const m = this.messages[card];
        return `<div class="bt-msg ${m ? m.kind : ""}">${m ? escapeHtml(m.text) : ""}</div>`;
      };

      // the inputs keep what was typed across renders
      const typed = {};
      for (const input of body.querySelectorAll("input[data-save]")) typed[input.dataset.save] = input.value;

      body.innerHTML = `
        <div class="bt">
          <div class="bt-card">
            <div class="bt-head"><h3>Server</h3><button type="button" class="bt-btn" data-refresh>Refresh</button></div>
            ${statusHtml}
            <div class="bt-links">
              <a data-link="commands">Chat commands</a>
              <a data-link="account">Account page</a>
              <a data-link="shop">Item finder page</a>
            </div>
          </div>
          <div class="bt-card">
            <div class="bt-head"><h3>Outfits</h3></div>
            ${list(this.saved && this.saved.outfits || [], "outfit")}
            <div class="bt-row">
              <input type="text" data-save="outfit" maxlength="20" placeholder="name (a-z, 0-9)" spellcheck="false">
              <button type="button" class="bt-btn primary" data-save-btn="outfit" ${this.busy ? "disabled" : ""}>Save current</button>
            </div>
            <div class="bt-row">
              <button type="button" class="bt-btn" data-run="!outfit off" data-card="outfit" ${this.busy ? "disabled" : ""}>Take everything off</button>
              <button type="button" class="bt-btn" data-run="!outfit undo" data-card="outfit" ${this.busy ? "disabled" : ""}>Undo</button>
            </div>
            ${msg("outfit")}
          </div>
          <div class="bt-card">
            <div class="bt-head"><h3>Den layouts</h3></div>
            <div class="bt-sub">Load one while in your den.</div>
            ${list(this.saved && this.saved.layouts || [], "den")}
            <div class="bt-row">
              <input type="text" data-save="den" maxlength="20" placeholder="name (a-z, 0-9)" spellcheck="false">
              <button type="button" class="bt-btn primary" data-save-btn="den" ${this.busy ? "disabled" : ""}>Save current</button>
            </div>
            <div class="bt-row">
              <button type="button" class="bt-btn" data-run="!den undo" data-card="den" ${this.busy ? "disabled" : ""}>Undo Clear Den</button>
            </div>
            ${msg("den")}
          </div>
          <div class="bt-card wide">
            <div class="bt-head"><h3>Land themes</h3></div>
            <div class="bt-sub">How Jamaa's lands look for you: this season's, or one from years past. Rooms show the new look the next time you enter them.</div>
            <div class="bt-chips">${themes}</div>
            ${msg("theme")}
          </div>
        </div>`;
      for (const input of body.querySelectorAll("input[data-save]")) {
        if (typed[input.dataset.save]) input.value = typed[input.dataset.save];
      }
    }

    _say(card, text, kind) {
      this.messages[card] = { text, kind };
    }

    async _run(card, call, args, done) {
      if (this.busy) return;
      this.busy = true;
      this.messages[card] = null;
      this.panel._render();
      const answer = await window.ipc.invoke(call, Object.assign({ username: globals.currentUser, token: globals.authToken }, args))
        .catch(err => ({ error: err.message }));
      this.busy = false;
      if (answer.error) this._say(card, answer.error, "err");
      else done(answer);
      this.panel._render();
      return answer;
    }

    onClick(event) {
      const body = this.panel._body;
      if (event.target.closest("[data-refresh]")) {
        this.status = null;
        this.panel._render();
        this.load();
        return;
      }
      const link = event.target.closest("[data-link]");
      if (link && globals.burrowServer) {
        window.ipc.send("openExternal", { url: `${globals.burrowServer}/${link.dataset.link}` });
        return;
      }
      const theme = event.target.closest("[data-theme]");
      if (theme) {
        const label = theme.textContent;
        this._run("theme", "burrow-theme", { theme: theme.dataset.theme }, () => {
          this.theme = theme.dataset.theme;
          this._say("theme", `${label} it is. Rooms change as you enter them.`, "ok");
        });
        return;
      }
      const run = event.target.closest("[data-run]");
      if (run) {
        const text = run.dataset.run;
        this._run(run.dataset.card, "burrow-command", { text }, () => {
          this._say(run.dataset.card, "Done.", "ok");
        });
        return;
      }
      const save = event.target.closest("[data-save-btn]");
      if (save) {
        const kind = save.dataset.saveBtn;
        const input = body.querySelector(`input[data-save="${kind}"]`);
        const name = input ? input.value.trim().toLowerCase() : "";
        if (!NAME.test(name)) {
          this._say(kind, "Names are 1 to 20 lowercase letters and digits.", "err");
          this.panel._render();
          return;
        }
        this._run(kind, "burrow-command", { text: `!${kind} savenew ${name}` }, () => {
          if (input) input.value = "";
          this._say(kind, `Saved as “${name}”.`, "ok");
          this.load();
        });
      }
    }
  };
})();
