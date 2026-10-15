"use strict";

// The mod menu's Item Finder tab on a Burrow server (ModMenuPanel shows it
// when globals.burrowServer is set): search the server's catalogue, see an
// item as the game draws it, pick a colour (clothing) or version (den items),
// and only then give it to the logged-in account. The calls and the pictures come from the main process
// (burrowItems.js). Runs on Chrome 87.
(() => {
  const KINDS = [
    { id: "all", title: "All" },
    { id: "clothing", title: "Clothing" },
    { id: "den", title: "Den items" },
  ];
  const SEARCH_DELAY_MS = 250;

  const escapeHtml = (value) => String(value == null ? "" : value)
    .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

  const hexOf = rgb => `#${((rgb >>> 0) & 0xffffff).toString(16).padStart(6, "0").toUpperCase()}`;

  // a swatch's colours as even stripes. One background rather than child
  // elements: Chrome 87 doesn't lay a <button> out as a flex box.
  const swatchBackground = colours => {
    const safe = colours.filter(c => /^#[0-9a-f]{6}$/i.test(c));
    if (!safe.length) return "transparent";
    const step = 100 / safe.length;
    return `linear-gradient(90deg, ${safe.map((c, i) => `${c} ${(i * step).toFixed(2)}% ${((i + 1) * step).toFixed(2)}%`).join(", ")})`;
  };

  const STYLE = `
    .bif-wrap { display: flex; flex-direction: column; gap: 10px; height: 100%; min-height: 0; }
    .bif-kinds { display: flex; gap: 6px; flex-shrink: 0; }
    .bif-kinds button {
      padding: 5px 12px;
      border-radius: 14px;
      border: 1px solid var(--mm-line);
      background: rgba(255, 255, 255, 0.03);
      color: var(--mm-dim);
      font: inherit;
      font-size: 12px;
      font-weight: 600;
      cursor: pointer;
    }
    .bif-kinds button:hover { color: var(--mm-text); }
    .bif-kinds button[aria-pressed="true"] { background: rgba(var(--mm-accent-rgb), 0.18); border-color: rgba(var(--mm-accent-rgb), 0.6); color: var(--mm-text); }
    .bif {
      flex: 1;
      display: grid;
      grid-template-columns: minmax(220px, 1fr) minmax(260px, 340px);
      gap: 12px;
      min-height: 0;
    }
    .bif-list {
      display: flex;
      flex-direction: column;
      gap: 4px;
      min-height: 0;
      overflow-y: auto;
      padding-right: 4px;
    }
    .bif-list::-webkit-scrollbar { width: 8px; }
    .bif-list::-webkit-scrollbar-thumb { border-radius: 8px; background: rgba(var(--mm-accent-rgb), 0.45); }
    .bif-row {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 8px 10px;
      border-radius: 9px;
      border: 1px solid transparent;
      background: var(--mm-card);
      cursor: pointer;
      user-select: none;
      transition: background 0.15s ease, border-color 0.15s ease;
    }
    .bif-row:hover { background: var(--mm-card-hover); border-color: rgba(var(--mm-accent-rgb), 0.35); }
    .bif-row.selected { background: rgba(var(--mm-accent-rgb), 0.12); border-color: rgba(var(--mm-accent-rgb), 0.6); }
    .bif-name { flex: 1; min-width: 0; font-size: 13px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .bif-meta { color: var(--mm-faint); font-size: 11px; white-space: nowrap; }
    .bif-kind {
      padding: 1px 7px;
      border-radius: 9px;
      font-size: 10px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.4px;
      background: rgba(255, 255, 255, 0.07);
      color: var(--mm-dim);
    }
    .bif-kind.den { background: rgba(120, 190, 255, 0.14); color: #9fcfff; }
    .bif-more { padding: 8px 4px; color: var(--mm-faint); font-size: 11.5px; text-align: center; }

    .bif-preview {
      display: flex;
      flex-direction: column;
      gap: 10px;
      min-height: 0;
      padding: 12px;
      border-radius: 12px;
      border: 1px solid var(--mm-line);
      background: rgba(0, 0, 0, 0.22);
      overflow-y: auto;
    }
    .bif-stage {
      position: relative;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 200px;
      flex-shrink: 0;
      border-radius: 10px;
      background:
        radial-gradient(circle at 50% 45%, rgba(var(--mm-accent-rgb), 0.16), transparent 70%),
        rgba(255, 255, 255, 0.03);
      overflow: hidden;
      color: var(--mm-faint);
      font-size: 12px;
      text-align: center;
    }
    .bif-stage canvas { image-rendering: auto; }
    .bif-stage iframe { width: 100%; height: 100%; border: 0; background: transparent; }
    .bif-info { display: flex; flex-direction: column; gap: 10px; flex: 1; min-height: 0; }
    .bif-title { font-size: 15px; font-weight: 700; line-height: 1.25; }
    .bif-facts { display: flex; flex-wrap: wrap; gap: 6px; color: var(--mm-dim); font-size: 11.5px; }
    .bif-facts span { padding: 2px 8px; border-radius: 8px; background: rgba(255, 255, 255, 0.05); }
    .bif-label { color: var(--mm-faint); font-size: 10.5px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; }
    .bif-swatches { display: flex; flex-wrap: wrap; gap: 6px; }
    .bif-swatch {
      width: 34px;
      height: 22px;
      padding: 0;
      border-radius: 6px;
      border: 2px solid rgba(255, 255, 255, 0.08);
      cursor: pointer;
    }
    .bif-swatch:hover { border-color: rgba(255, 255, 255, 0.4); }
    .bif-swatch.selected { border-color: var(--mm-accent); box-shadow: 0 0 0 2px rgba(var(--mm-accent-rgb), 0.3); }
    .bif-swatch.custom {
      width: auto;
      padding: 0 9px;
      background: rgba(255, 255, 255, 0.05);
      color: var(--mm-dim);
      font: inherit;
      font-size: 11px;
      font-weight: 600;
    }
    .bif-custom { display: flex; flex-direction: column; gap: 7px; }
    .bif-slots { display: flex; gap: 6px; align-items: center; }
    .bif-slot {
      width: 30px;
      height: 26px;
      border-radius: 6px;
      border: 2px solid rgba(255, 255, 255, 0.12);
      cursor: pointer;
      padding: 0;
    }
    .bif-slot.editing { border-color: var(--mm-accent); box-shadow: 0 0 0 2px rgba(var(--mm-accent-rgb), 0.3); }
    .bif-code {
      flex: 1;
      min-width: 0;
      height: 28px;
      padding: 0 8px;
      border-radius: 7px;
      border: 1px solid var(--mm-line);
      background: rgba(0, 0, 0, 0.25);
      color: var(--mm-text);
      font: inherit;
      font-size: 12px;
      outline: none;
    }
    .bif-code:focus { border-color: rgba(var(--mm-accent-rgb), 0.7); }
    .bif-hexrow { display: flex; gap: 8px; align-items: center; }
    .bif-hexrow .bif-code { flex: 0 0 92px; font-family: ui-monospace, Consolas, monospace; }
    .bif-palette { display: grid; grid-template-columns: repeat(16, 1fr); gap: 2px; }
    .bif-palette button { height: 14px; padding: 0; border: 0; border-radius: 2px; cursor: pointer; }
    .bif-palette button:hover { outline: 2px solid #fff; outline-offset: -1px; }
    .bif-palette button.on { outline: 2px solid var(--mm-accent); outline-offset: -1px; }
    .bif-give {
      margin-top: auto;
      height: 36px;
      border: 0;
      border-radius: 9px;
      background: var(--mm-accent);
      color: var(--mm-on-accent);
      font: inherit;
      font-size: 13px;
      font-weight: 700;
      cursor: pointer;
      transition: filter 0.15s ease, transform 0.1s ease;
    }
    .bif-give:hover { filter: brightness(1.12); }
    .bif-give:active { transform: scale(0.98); }
    .bif-give:disabled { opacity: 0.5; cursor: default; filter: none; transform: none; }
    .bif-status { min-height: 16px; font-size: 12px; color: var(--mm-dim); }
    .bif-status.ok { color: #4ade80; }
    .bif-status.err { color: #f87171; }
    .bif-hint { color: var(--mm-faint); font-size: 12px; line-height: 1.45; }
    .body.bif-body { overflow: hidden; }
  `;

  window.BurrowItemFinder = class {
    constructor(panel) {
      this.panel = panel; // the ajd-mod-menu-panel element
      this.kind = "all";
      this.query = "";
      this.results = null; // null = not searched yet
      this.total = 0;
      this.error = "";
      this.selected = null; // a result row
      this.colorIndex = 0;
      // a raw colour code (string) in place of the item's own colours, or null
      this.custom = null;
      // four RGB values (hex colours) in place of the code, or null. Burrow
      // makes a colour id for them (its "xcc") when the item is given.
      this.rgbs = null;
      this.denVersion = 0; // a den item's version (its colours), from the item's own list
      this.denVersions = null; // what the preview loader found: null = not yet
      this._versionsTimer = null;
      this.editSlot = null; // which of the code's four parts the palette is picking
      this.palette = null; // the game palette, "#rrggbb" x 256, once loaded
      this.preview = null; // { key, data } | { key, loading } | { key, error }
      this.status = { text: "", kind: "" };
      this.giving = false;
      this._searchSeq = 0;
      this._previewSeq = 0;
      this._searchTimer = null;

      const style = document.createElement("style");
      style.textContent = STYLE;
      panel.shadowRoot.appendChild(style);
    }

    // what the search box and the summary say while the finder is shown
    get placeholder() {
      return "Search items by name or id…";
    }

    summary() {
      if (!this.results) return "";
      return `<b>${this.total}</b> item${this.total === 1 ? "" : "s"} found`;
    }

    // first shown: the first search
    activate() {
      if (!this.results) this.search();
    }

    setKind(kind) {
      if (!KINDS.some(k => k.id === kind) || kind === this.kind) return;
      this.kind = kind;
      this.search();
    }

    setQuery(query) {
      this.query = String(query || "");
      clearTimeout(this._searchTimer);
      this._searchTimer = setTimeout(() => this.search(), SEARCH_DELAY_MS);
    }

    async search() {
      const seq = ++this._searchSeq;
      this.error = "";
      const found = await window.ipc.invoke("burrow-items-search", {
        kind: this.kind,
        query: this.query.trim(),
        username: globals.currentUser,
        token: globals.authToken,
      }).catch(err => ({ error: err.message }));
      if (seq !== this._searchSeq) return;
      if (found.error) {
        this.error = found.error;
        this.results = [];
        this.total = 0;
      }
      else {
        this.results = found.results;
        this.total = found.total;
      }
      this.panel._render();
    }

    render(body) {
      body.classList.add("bif-body");
      let root = body.querySelector(".bif");
      if (!root) {
        body.innerHTML = `<div class="bif-wrap"><div class="bif-kinds"></div><div class="bif"><div class="bif-list"></div><div class="bif-preview"><div class="bif-stage"></div><div class="bif-info"></div></div></div></div>`;
        root = body.querySelector(".bif");
        this._stageKey = null;
      }
      body.querySelector(".bif-kinds").innerHTML = KINDS.map(kind =>
        `<button type="button" data-kind="${kind.id}" aria-pressed="${kind.id === this.kind}">${kind.title}</button>`).join("");
      root.querySelector(".bif-list").innerHTML = this._listHtml();
      root.querySelector(".bif-info").innerHTML = this._infoHtml();
      const codeInput = root.querySelector("[data-code]");
      if (codeInput && !codeInput.readOnly) codeInput.addEventListener("change", () => this._setCustom(codeInput.value.trim()));
      const hexInput = root.querySelector("[data-hex]");
      if (hexInput) hexInput.addEventListener("change", () => this._setHex(this.editSlot, hexInput.value.trim()));
      this._paintStage(root.querySelector(".bif-stage"));
    }

    _listHtml() {
      if (!this.results) return `<div class="status">Searching…</div>`;
      if (this.error) return `<div class="status">${escapeHtml(this.error)}</div>`;
      if (!this.results.length) {
        return `<div class="empty">${this.query.trim() ? `No items match “${escapeHtml(this.query.trim())}”.` : "Nothing here."}</div>`;
      }
      const rows = this.results.map(item => {
        const key = `${item.kind}:${item.id}`;
        const selected = this.selected && `${this.selected.kind}:${this.selected.id}` === key;
        return `
          <div class="bif-row${selected ? " selected" : ""}" data-item="${escapeHtml(key)}">
            <span class="bif-kind ${item.kind === "den" ? "den" : ""}">${item.kind === "den" ? "Den" : "Wear"}</span>
            <span class="bif-name">${escapeHtml(item.name || `#${item.id}`)}</span>
            <span class="bif-meta">#${escapeHtml(item.id)}</span>
          </div>`;
      }).join("");
      const more = this.total > this.results.length
        ? `<div class="bif-more">Showing ${this.results.length} of ${this.total}. Type more to narrow it down.</div>`
        : "";
      return rows + more;
    }

    _infoHtml() {
      const item = this.selected;
      if (!item) {
        return `
          <div class="bif-hint">Items go straight into the account you're playing on. Nothing is given until you press Give.</div>`;
      }
      const data = this.preview && this.preview.data;
      let swatches = "";
      if (item.kind === "clothing" && data && data.swatches) {
        swatches = `
          <div class="bif-label">Colour</div>
          <div class="bif-swatches">${data.swatches.map((colours, index) => `
            <button type="button" class="bif-swatch${this.custom === null && index === this.colorIndex ? " selected" : ""}" data-color="${index}" title="Colour ${index + 1}" style="background: ${swatchBackground(colours)}"></button>`).join("")}
            <button type="button" class="bif-swatch custom${this.custom !== null ? " selected" : ""}" data-custom title="Any colour: rare and beta colourings">Custom</button>
          </div>
          ${this.custom !== null ? this._customHtml() : ""}`;
      }
      if (item.kind === "den" && this.denVersions && this.denVersions.length > 1) {
        swatches = `
          <div class="bif-label">Version</div>
          <div class="bif-swatches">${this.denVersions.map((version, index) => `
            <button type="button" class="bif-swatch custom${version === this.denVersion ? " selected" : ""}" data-den-version="${version}" title="Version ${index + 1}">${index + 1}</button>`).join("")}
          </div>`;
      }
      const facts = [
        item.kind === "den" ? "Den item" : "Clothing",
        `ID ${item.id}`,
        item.cost ? `${Number(item.cost).toLocaleString()} gems` : "Free",
      ];
      return `
        <div class="bif-title">${escapeHtml(item.name || `#${item.id}`)}</div>
        <div class="bif-facts">${facts.map(f => `<span>${escapeHtml(f)}</span>`).join("")}</div>
        ${swatches}
        <div class="bif-status ${this.status.kind}">${escapeHtml(this.status.text)}</div>
        <button type="button" class="bif-give" data-give ${this.giving ? "disabled" : ""}>${this.giving ? "Giving…" : `Give to ${escapeHtml(globals.currentUser || "me")}`}</button>`;
    }

    // the custom colour: its four parts (game palette indices, high byte first),
    // the code itself, and the palette while a part is being picked
    _customHtml() {
      const code = Number(this.custom) >>> 0;
      const parts = [code >>> 24, (code >>> 16) & 0xff, (code >>> 8) & 0xff, code & 0xff];
      const rgbs = this._partRgbs();
      const colourOf = slot => (rgbs ? hexOf(rgbs[slot]) : "#444");
      const slots = parts.map((index, slot) =>
        `<button type="button" class="bif-slot${this.editSlot === slot ? " editing" : ""}" data-slot="${slot}" title="Part ${slot + 1}: ${this.rgbs ? hexOf(this.rgbs[slot]) : `palette colour ${index}`}" style="background:${escapeHtml(colourOf(slot))}"></button>`).join("");
      const palette = this.editSlot === null || !this.palette ? "" : `
        <div class="bif-palette">${this.palette.map((hex, i) =>
          `<button type="button" data-pal="${i}" class="${!this.rgbs && parts[this.editSlot] === i ? "on" : ""}" title="${i}" style="background:${escapeHtml(hex)}"></button>`).join("")}</div>
        <div class="bif-hexrow"><input class="bif-code" data-hex value="${escapeHtml(rgbs ? hexOf(rgbs[this.editSlot]) : "")}" maxlength="7" spellcheck="false" title="Any colour for this part"><span class="bif-hint">or any hex colour for part ${this.editSlot + 1}, e.g. #FF8800</span></div>`;
      const codeBox = this.rgbs
        ? `<input class="bif-code" data-code readonly value="${escapeHtml(this.rgbs.map(hexOf).join(" "))}" title="Hex colours: Burrow gives them a colour ID when you give the item">`
        : `<input class="bif-code" data-code value="${escapeHtml(this.custom)}" spellcheck="false" title="Colour ID: the same code Burrow's own item finder takes">`;
      return `
        <div class="bif-custom">
          <div class="bif-slots">${slots}${codeBox}</div>
          ${palette}
          <div class="bif-hint">Pick a part, then a colour or a hex code. Rare colourings like the Pearly, Milky and Beta Tiara are this item in other colours.</div>
        </div>`;
    }

    // the custom colour's four parts as RGB values, or null before the
    // palette is in
    _partRgbs() {
      if (this.rgbs) return this.rgbs.slice();
      if (!this.palette || this.custom === null) return null;
      const code = Number(this.custom) >>> 0;
      return [code >>> 24, (code >>> 16) & 0xff, (code >>> 8) & 0xff, code & 0xff].map(i => parseInt(this.palette[i].slice(1), 16));
    }

    _setHex(slot, text) {
      if (slot === null || slot === undefined) return;
      const match = /^#?([0-9a-f]{6})$/i.exec(text);
      const rgbs = this._partRgbs();
      if (!match || !rgbs) {
        this.status = { text: rgbs ? "A hex colour looks like #FF8800." : "The palette is still loading.", kind: "err" };
        this.panel._render();
        return;
      }
      rgbs[slot] = parseInt(match[1], 16);
      this._setRgbs(rgbs);
    }

    // four RGB values. Ones that are all game palette colours become the
    // usual colour code, which needs nothing new from the server.
    _setRgbs(rgbs) {
      const indexes = rgbs.map(rgb => this.palette.findIndex(hex => parseInt(hex.slice(1), 16) === rgb));
      if (indexes.every(i => i >= 0)) {
        this._setCustom(String(((indexes[0] << 24) | (indexes[1] << 16) | (indexes[2] << 8) | indexes[3]) >>> 0));
        return;
      }
      this.rgbs = rgbs;
      this.status = { text: "", kind: "" };
      this._loadPreview();
    }

    _setCustom(code) {
      const n = Number(code);
      if (!/^\d{1,10}$/.test(String(code)) || n > 0xffffffff) {
        this.status = { text: "A colour ID is a whole number from 0 to 4294967295.", kind: "err" };
        this.panel._render();
        return;
      }
      this.custom = String(n >>> 0);
      this.rgbs = null;
      this.status = { text: "", kind: "" };
      this._loadPreview();
    }

    async _loadPalette() {
      if (this.palette) return;
      const answer = await window.ipc.invoke("burrow-palette").catch(err => ({ error: err.message }));
      if (answer.colours) {
        this.palette = answer.colours;
        this.panel._render();
      }
    }

    // the picture: a canvas for clothing, the item's own SWF for den items.
    // Only redrawn when it changes: a plugin element reloads whenever it is
    // put back in the page.
    _paintStage(stage) {
      const item = this.selected;
      const preview = this.preview;
      const key = !item ? "none"
        : !preview || preview.loading ? `loading:${preview ? preview.key : ""}`
        : preview.error ? `error:${preview.key}`
        : preview.key;
      if (key === this._stageKey) return;
      this._stageKey = key;
      if (!item) {
        stage.textContent = "Pick an item to preview it.";
        return;
      }
      if (!preview || preview.loading) {
        stage.textContent = "Loading preview…";
        return;
      }
      if (preview.error) {
        stage.textContent = preview.error;
        return;
      }
      const data = preview.data;
      const box = { width: Math.max(stage.clientWidth - 24, 120), height: Math.max(stage.clientHeight - 24, 120) };
      const keep = node => {
        stage.textContent = "";
        stage.appendChild(node);
      };
      if (data.kind === "clothing" && data.image) {
        const { width, height } = data.image;
        const bytes = Uint8ClampedArray.from(atob(data.image.rgba), c => c.charCodeAt(0));
        const source = document.createElement("canvas");
        source.width = width;
        source.height = height;
        source.getContext("2d").putImageData(new ImageData(bytes, width, height), 0, 0);
        const scale = Math.min(box.width / width, box.height / height, 3);
        const canvas = document.createElement("canvas");
        canvas.width = Math.round(width * scale);
        canvas.height = Math.round(height * scale);
        const ctx = canvas.getContext("2d");
        ctx.imageSmoothingQuality = "high";
        ctx.drawImage(source, 0, 0, canvas.width, canvas.height);
        keep(canvas);
        return;
      }
      if (data.kind === "den" && data.view) {
        // the preview server's page, where the loader shows the item in the
        // chosen version (Flash only starts on the SWF's own origin)
        const frame = document.createElement("iframe");
        frame.setAttribute("scrolling", "no");
        frame.src = `${data.view}&v=${this.denVersion}`;
        keep(frame);
        this._watchVersions(data.token);
        return;
      }
      stage.textContent = "No preview for this item.";
    }

    // the loader reports the item's versions to the main process once it has
    // the item; asked for every 400ms for up to 30s (Flash can be slow to start)
    _watchVersions(token) {
      clearInterval(this._versionsTimer);
      if (this.denVersions) return;
      const started = Date.now();
      this._versionsTimer = setInterval(async () => {
        const answer = await window.ipc.invoke("burrow-den-versions", { token }).catch(() => ({}));
        const item = this.selected;
        if (!item || item.kind !== "den" || !this.preview || !this.preview.data || this.preview.data.token !== token) {
          clearInterval(this._versionsTimer);
          return;
        }
        if (Array.isArray(answer.versions) || answer.versions === "error" || Date.now() - started > 30000) {
          clearInterval(this._versionsTimer);
          this.denVersions = Array.isArray(answer.versions) ? answer.versions : [];
          this.panel._render();
        }
      }, 400);
    }

    async _loadPreview() {
      const item = this.selected;
      if (!item) return;
      const key = `${item.kind}:${item.id}:${item.kind === "clothing" ? (this.rgbs ? `h${this.rgbs.join(",")}` : this.custom !== null ? `c${this.custom}` : this.colorIndex) : `v${this.denVersion}`}`;
      const seq = ++this._previewSeq;
      // a colour change keeps the old picture up until the new one is in
      if (!this.preview || !this.preview.data || this.preview.data.kind !== item.kind || !this.preview.key.startsWith(`${item.kind}:${item.id}:`)) {
        this.preview = { key, loading: true };
        this.panel._render();
      }
      const data = await window.ipc.invoke("burrow-items-preview", {
        kind: item.kind,
        id: item.id,
        colorIndex: this.colorIndex,
        color: item.kind === "clothing" && this.custom !== null ? this.custom : undefined,
        rgbs: item.kind === "clothing" && this.rgbs ? this.rgbs : undefined,
      }).catch(err => ({ error: err.message }));
      if (seq !== this._previewSeq) return;
      this.preview = data.error ? { key, error: data.error } : { key, data };
      this.panel._render();
    }

    onClick(event) {
      const kind = event.target.closest("[data-kind]");
      if (kind) {
        this.setKind(kind.dataset.kind);
        this.panel._render();
        return;
      }
      const row = event.target.closest("[data-item]");
      if (row) {
        const [kind, id] = row.dataset.item.split(":");
        const item = (this.results || []).find(r => r.kind === kind && String(r.id) === id);
        if (item && (!this.selected || this.selected !== item)) {
          this.selected = item;
          this.colorIndex = 0;
          this.custom = null;
          this.rgbs = null;
          this.editSlot = null;
          this.denVersion = 0;
          this.denVersions = null;
          this.status = { text: "", kind: "" };
          this._loadPreview();
        }
        return;
      }
      const swatch = event.target.closest("[data-color]");
      if (swatch) {
        this.colorIndex = Number(swatch.dataset.color) || 0;
        this.custom = null;
        this.rgbs = null;
        this.editSlot = null;
        this._loadPreview();
        return;
      }
      const denVersion = event.target.closest("[data-den-version]");
      if (denVersion) {
        this.denVersion = Number(denVersion.dataset.denVersion) || 0;
        this._loadPreview();
        return;
      }
      if (event.target.closest("[data-custom]")) {
        if (this.custom === null) {
          // start from the shop colour showing, so it can be adjusted
          const codes = this.preview && this.preview.data && this.preview.data.codes;
          this._setCustom(codes && codes[this.colorIndex] ? codes[this.colorIndex] : "0");
          this._loadPalette();
        }
        return;
      }
      const slot = event.target.closest("[data-slot]");
      if (slot) {
        const index = Number(slot.dataset.slot);
        this.editSlot = this.editSlot === index ? null : index;
        this._loadPalette();
        this.panel._render();
        return;
      }
      const pal = event.target.closest("[data-pal]");
      if (pal && this.editSlot !== null && this.rgbs) {
        const rgbs = this.rgbs.slice();
        rgbs[this.editSlot] = parseInt(this.palette[Number(pal.dataset.pal)].slice(1), 16);
        this._setRgbs(rgbs);
        return;
      }
      if (pal && this.editSlot !== null && this.custom !== null) {
        const shift = (3 - this.editSlot) * 8;
        const code = Number(this.custom) >>> 0;
        const next = ((code & ~(0xff << shift)) | (Number(pal.dataset.pal) << shift)) >>> 0;
        this._setCustom(String(next));
        return;
      }
      if (event.target.closest("[data-give]")) this.give();
    }

    async give() {
      const item = this.selected;
      if (!item || this.giving) return;
      this.giving = true;
      this.status = { text: "", kind: "" };
      this.panel._render();
      const hex = item.kind === "clothing" && this.rgbs ? await this._customColourId(this.rgbs) : null;
      const answer = hex && hex.error ? hex
        : item.kind === "den" && this.denVersion > 0
        ? await this._buyDenVersion(item.id, this.denVersion)
        : await window.ipc.invoke("burrow-items-give", {
          kind: item.kind,
          id: item.id,
          colorIndex: this.colorIndex,
          color: hex ? String(hex.id) : item.kind === "clothing" && this.custom !== null ? this.custom : undefined,
          username: globals.currentUser,
          token: globals.authToken,
        }).catch(err => ({ error: err.message }));
      this.giving = false;
      this.status = answer.error
        ? { text: answer.error, kind: "err" }
        : { text: `${item.name || "Item"} added to your ${item.kind === "den" ? "den items" : "clothing"}.`, kind: "ok" };
      this.panel._render();
    }

    // Burrow's id for four hex colours, from the game (the patched client's
    // sjModMenuCustomColour): an existing one at once, a new one after the
    // game's "xcc" has been answered. Burrow limits new colours per day.
    async _customColourId(rgbs) {
      const call = (method, ...args) => this.panel.bridge.call(method, ...args);
      try {
        let id = await call("sjModMenuCustomColour", rgbs, true);
        for (let waited = 0; id < 0 && waited < 8000; waited += 250) {
          await new Promise(resolve => setTimeout(resolve, 250));
          id = await call("sjModMenuCustomColour", rgbs, false);
        }
        return id >= 0 ? { id } : { error: "Burrow didn't make that colour (it allows a few new colours a day)." };
      }
      catch (err) {
        return { error: "Hex colours need the Strawberry Jam game client with this feature (the Burrow test client)." };
      }
    }

    // Burrow's give call always gives a den item's first version, so another
    // version goes through the game's own den shop purchase (the patched
    // client's sjModMenuBuyDenItem), which Burrow takes for any den item; it
    // costs the item's price, and Burrow tops currency up at every login.
    async _buyDenVersion(id, version) {
      const call = (method, ...args) => this.panel.bridge.call(method, ...args);
      try {
        if (!(await call("sjModMenuBuyDenItem", Number(id), Number(version)))) {
          return { error: "The game didn't take that." };
        }
        for (let waited = 0; waited < 8000; waited += 250) {
          await new Promise(resolve => setTimeout(resolve, 250));
          const status = await call("sjModMenuDenBuyStatus");
          if (status === 1) return { ok: true };
          if (status === 0) return { error: "The server refused it (a full den inventory?)." };
        }
        return { error: "No answer from the server. Check your den items." };
      }
      catch (err) {
        return { error: "Other versions need the Strawberry Jam game client with this feature (the Burrow test client)." };
      }
    }
  };
})();
