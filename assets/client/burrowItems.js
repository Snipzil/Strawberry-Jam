"use strict";

// The Burrow item finder for the mod menu (gui/components/screens/BurrowItemFinder.js):
// the server's item search and give calls, and a preview of each item drawn
// the way the game draws its icons.
//
// The calls are made from here because a Burrow server's /api only answers
// requests without a foreign Origin (its lib/limits.js), and the login page
// is a file. The preview reads the game's own assets from the server's CDN
// mirror:
//   clothing: imageArrays/<avatar<<24 | iconId<<16 | layerDefId>, a palette-
//     indexed run-length bitmap coloured from paletteData (the game's
//     SimpleIcon, LayerBitmap and PaletteHelper), drawn here into RGBA;
//   den items: items/<defId<<16 | iconId>, an SWF the game shows as is
//     (DenItemHelper). The page's Flash shows it through denPreview.swf
//     (scripts/den-preview), which loads it from a server here on 127.0.0.1,
//     sets the version (a den item's colours) and reports which versions the
//     item has.

const crypto = require("crypto");
const fs = require("fs");
const http = require("http");
const https = require("https");
const path = require("path");
const zlib = require("zlib");

const TIMEOUT_MS = 15000;
const DEF_ITEM = 1000;
const DEF_DEN_ITEM = 1030;
const CLOTHING_AVATAR = 1;
const CLOTHING_ICON_IDS = [26, 25]; // the game's non-shop and shop icons
const IMAGE_ARRAY_VERSION = 117967104;
const PREVIEW_LOADER = path.join(__dirname, "denPreview.swf");
const MAX_PREVIEW_ITEMS = 50;

// ---------------------------------------------------------------- AMF3 --

// Reads the AMF3 the game's assets are written in. Arrays come back as plain
// objects holding both their named and their numbered entries; byte arrays as
// Buffers.
const decodeAmf3 = buffer => {
  let pos = 0;
  const strings = [];
  const objects = [];
  const traits = [];

  const u8 = () => buffer[pos++];
  const u29 = () => {
    let value = 0;
    for (let i = 0; i < 3; i++) {
      const b = u8();
      if (b < 0x80) return (value << 7) | b;
      value = (value << 7) | (b & 0x7f);
    }
    return (value << 8) | u8();
  };
  const string = () => {
    const ref = u29();
    if ((ref & 1) === 0) return strings[ref >> 1];
    const length = ref >> 1;
    const value = buffer.toString("utf8", pos, pos + length);
    pos += length;
    if (length) strings.push(value);
    return value;
  };
  const value = () => {
    const marker = u8();
    switch (marker) {
      case 0x00: return undefined;
      case 0x01: return null;
      case 0x02: return false;
      case 0x03: return true;
      case 0x04: {
        const n = u29();
        return n & 0x10000000 ? n - 0x20000000 : n;
      }
      case 0x05: {
        const n = buffer.readDoubleBE(pos);
        pos += 8;
        return n;
      }
      case 0x06: return string();
      case 0x07:
      case 0x0b: {
        const ref = u29();
        if ((ref & 1) === 0) return objects[ref >> 1];
        const text = buffer.toString("utf8", pos, pos + (ref >> 1));
        pos += ref >> 1;
        objects.push(text);
        return text;
      }
      case 0x08: {
        const ref = u29();
        if ((ref & 1) === 0) return objects[ref >> 1];
        const date = new Date(buffer.readDoubleBE(pos));
        pos += 8;
        objects.push(date);
        return date;
      }
      case 0x09: {
        const ref = u29();
        if ((ref & 1) === 0) return objects[ref >> 1];
        const out = {};
        objects.push(out);
        for (let key = string(); key !== ""; key = string()) out[key] = value();
        const dense = ref >> 1;
        for (let i = 0; i < dense; i++) out[i] = value();
        return out;
      }
      case 0x0a: {
        const ref = u29();
        if ((ref & 1) === 0) return objects[ref >> 1];
        let trait;
        if ((ref & 3) === 1) {
          trait = traits[ref >> 2];
        }
        else {
          trait = { externalizable: (ref & 4) !== 0, dynamic: (ref & 8) !== 0, names: [] };
          string(); // class name
          const count = ref >> 4;
          for (let i = 0; i < count; i++) trait.names.push(string());
          traits.push(trait);
        }
        if (trait.externalizable) throw new Error("externalizable AMF3 objects are not supported");
        const out = {};
        objects.push(out);
        for (const name of trait.names) out[name] = value();
        if (trait.dynamic) {
          for (let key = string(); key !== ""; key = string()) out[key] = value();
        }
        return out;
      }
      case 0x0c: {
        const ref = u29();
        if ((ref & 1) === 0) return objects[ref >> 1];
        const bytes = buffer.subarray(pos, pos + (ref >> 1));
        pos += ref >> 1;
        objects.push(bytes);
        return bytes;
      }
      default:
        throw new Error(`unsupported AMF3 marker 0x${marker.toString(16)} at ${pos - 1}`);
    }
  };
  return value();
};

// ------------------------------------------------------------- the CDN --

// mirrors LoaderCache.hashItV2 in the client: the last part of every
// versioned asset path is obfuscated this way (Burrow's lib/cdn.js).
const hashName = name => {
  const salted = "W3 7r4Ck h4X0r3rs" + name;
  let out = "";
  for (let i = 0; i < salted.length; i++) {
    out = i % 2 === 0 ? out + salted[i] : salted[i] + out;
  }
  return crypto.createHash("md5").update(out).digest("hex");
};

const request = (url, { method = "GET", body = null } = {}) => new Promise((resolve, reject) => {
  const lib = url.startsWith("https:") ? https : http;
  const headers = body ? { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(body) } : {};
  const req = lib.request(url, { method, headers, timeout: TIMEOUT_MS }, res => {
    const chunks = [];
    res.on("data", chunk => chunks.push(chunk));
    res.on("end", () => resolve({ status: res.statusCode, body: Buffer.concat(chunks) }));
  });
  req.on("timeout", () => req.destroy(new Error("The Burrow server did not answer in time.")));
  req.on("error", reject);
  if (body) req.write(body);
  req.end();
});

const json = response => {
  try {
    return JSON.parse(response.body.toString("utf8"));
  }
  catch (_) {
    return {};
  }
};

// per server: its deploy version, the palette and the item tables, each
// fetched once.
const servers = new Map();

const serverData = server => {
  if (!servers.has(server)) servers.set(server, {});
  return servers.get(server);
};

const deployOf = async server => {
  const data = serverData(server);
  if (!data.deploy) {
    data.deploy = (async () => {
      const flashVars = json(await request(`${server}/flashvars`));
      if (!flashVars.deploy_version) throw new Error("Not a Burrow server.");
      return String(flashVars.deploy_version);
    })().catch(err => {
      data.deploy = null;
      throw err;
    });
  }
  return data.deploy;
};

// an asset by its unhashed path ("defPacks/1000"), or null when there is none
const asset = async (server, assetPath) => {
  const deploy = await deployOf(server);
  const parts = assetPath.split("/");
  parts.push(hashName(parts.pop()));
  const response = await request(`${server}/${deploy}/${parts.join("/")}`);
  return response.status === 200 ? response.body : null;
};

const cached = (server, key, load) => {
  const data = serverData(server);
  if (!data[key]) {
    data[key] = load().catch(err => {
      data[key] = null;
      throw err;
    });
  }
  return data[key];
};

const defPack = (server, id) => cached(server, `defPack${id}`, async () => {
  const raw = await asset(server, `defPacks/${id}`);
  if (!raw) throw new Error(`The server has no item table ${id}.`);
  const rows = new Map();
  for (const row of Object.values(decodeAmf3(zlib.inflateRawSync(raw)))) {
    if (row && row.id !== undefined) rows.set(Number(row.id), row);
  }
  return rows;
});

// the game palette: 256 colours as 0x00RRGGBB (PaletteHelper.setGamePalette)
const gamePalette = server => cached(server, "palette", async () => {
  const raw = await asset(server, "paletteData");
  if (!raw) throw new Error("The server has no game palette.");
  const length = raw.readInt32BE(0);
  const palette = [];
  for (let i = 0; i < length / 4; i++) palette.push(raw.readUInt32BE(4 + i * 4));
  return palette;
});

// ---------------------------------------------------- clothing preview --

// PaletteHelper.setColorGradient: `count` shades of `rgb`, darkest first,
// at four opacities 25 entries apart.
const setColorGradient = (pal, rgb, start, count) => {
  let r = (rgb >> 16) & 0xff;
  let g = (rgb >> 8) & 0xff;
  let b = rgb & 0xff;
  const stepR = Math.floor(r / (count + 2));
  const stepG = Math.floor(g / (count + 2));
  const stepB = Math.floor(b / (count + 2));
  let index = start + count - 1;
  for (let i = 0; i < count; i++) {
    const colour = ((r << 16) | (g << 8) | b) >>> 0;
    pal[index] = (colour | 0xff000000) >>> 0;
    pal[index + 25] = (colour | 0xc0000000) >>> 0;
    pal[index + 50] = (colour | 0x80000000) >>> 0;
    pal[index + 75] = (colour | 0x40000000) >>> 0;
    r -= stepR;
    g -= stepG;
    b -= stepB;
    index--;
  }
};

const mixColors = (one, other) => {
  const r = Math.floor((((one >> 16) & 0xff) + ((other >> 16) & 0xff)) / 2);
  const g = Math.floor((((one >> 8) & 0xff) + ((other >> 8) & 0xff)) / 2);
  const b = Math.floor(((one & 0xff) + (other & 0xff)) / 2);
  return (r << 16) | (g << 8) | b;
};

// PaletteHelper.BuildAnimalPalette from an item colour: four game palette
// indices packed in one uint.
const itemPalette = (palette, colour) => rgbPalette([
  palette[(colour >>> 24) & 0xff] || 0,
  palette[(colour >>> 16) & 0xff] || 0,
  palette[(colour >>> 8) & 0xff] || 0,
  palette[colour & 0xff] || 0,
]);

// the same from four RGB values (a Burrow custom colour)
const rgbPalette = ([c1, c2, c3, c4]) => {
  const pal = [];
  setColorGradient(pal, c1, 1, 3);
  setColorGradient(pal, c2, 4, 3);
  setColorGradient(pal, c3, 7, 3);
  setColorGradient(pal, c4, 10, 3);
  setColorGradient(pal, mixColors(c1, c2), 13, 2);
  setColorGradient(pal, mixColors(c2, c3), 15, 2);
  setColorGradient(pal, mixColors(c1, c3), 17, 2);
  setColorGradient(pal, mixColors(c1, c4), 19, 2);
  setColorGradient(pal, mixColors(c2, c4), 21, 2);
  setColorGradient(pal, mixColors(c3, c4), 23, 2);
  return pal;
};

// LayerBitmap.paintFrame for one frame on an empty bitmap: a run-length list
// of palette indices (0 = skip), where entries under full opacity blend with
// what is already drawn.
const paintFrame = (frame, pal) => {
  const width = Number(frame.w);
  const height = Number(frame.h);
  const bytes = frame.b;
  const pixels = new Uint32Array(width * height); // 0xAARRGGBB
  let x = 0;
  let y = 0;
  const put = colour => {
    if (x >= 0 && x < width && y >= 0 && y < height) pixels[y * width + x] = colour;
  };
  const get = () => (x >= 0 && x < width && y >= 0 && y < height ? pixels[y * width + x] : 0);
  let pos = 0;
  while (pos < bytes.length) {
    let index = bytes[pos++];
    let run = 1;
    if (index & 0x80) {
      index &= 0x7f;
      run = bytes[pos++] + 1;
    }
    if (index === 0) {
      x += run;
      if (x >= width) {
        const over = x - width;
        x = over % width;
        y += Math.floor(over / width) + 1;
      }
      continue;
    }
    const colour = (pal[index] || 0) >>> 0;
    if (colour >= 0xff000000) {
      while (run-- > 0) {
        put(colour);
        if (++x === width) {
          x = 0;
          y++;
        }
      }
      continue;
    }
    while (run-- > 0) {
      const under = get();
      let out = colour;
      if (under !== 0) {
        let alpha = colour >>> 24;
        let r = (colour >> 16) & 0xff;
        let g = (colour >> 8) & 0xff;
        let b = colour & 0xff;
        const underAlpha = under >>> 24;
        const ur = (under >> 16) & 0xff;
        const ug = (under >> 8) & 0xff;
        const ub = under & 0xff;
        if (alpha === 192) {
          r = (r * 3 + ur) * 0.25;
          g = (g * 3 + ug) * 0.25;
          b = (b * 3 + ub) * 0.25;
        }
        else if (alpha === 128) {
          r = (r + ur) * 0.5;
          g = (g + ug) * 0.5;
          b = (b + ub) * 0.5;
        }
        else {
          r = (r + ur * 3) * 0.25;
          g = (g + ug * 3) * 0.25;
          b = (b + ub * 3) * 0.25;
        }
        if (underAlpha > alpha) alpha = underAlpha;
        out = ((alpha << 24) | (r << 16) | (g << 8) | b) >>> 0;
      }
      put(out);
      if (++x === width) {
        x = 0;
        y++;
      }
    }
  }
  // as RGBA bytes for a canvas
  const rgba = Buffer.alloc(width * height * 4);
  for (let i = 0; i < pixels.length; i++) {
    const p = pixels[i];
    rgba[i * 4] = (p >> 16) & 0xff;
    rgba[i * 4 + 1] = (p >> 8) & 0xff;
    rgba[i * 4 + 2] = p & 0xff;
    rgba[i * 4 + 3] = p >>> 24;
  }
  return { width, height, rgba };
};

// a raw colour code (four game palette indices in one uint, as Burrow's own
// finder takes in its "Colour ID" box), or null when `value` isn't one
const rawColour = value => {
  if (value === undefined || value === null || value === "") return null;
  const text = String(value).trim();
  if (!/^\d{1,10}$/.test(text)) return null;
  const n = Number(text);
  return n <= 0xffffffff ? n >>> 0 : null;
};

// four RGB values (hex colours), or null
const rgbColours = value => Array.isArray(value) && value.length === 4 && value.every(c => Number.isInteger(c) && c >= 0 && c <= 0xffffff)
  ? value.slice() : null;

// `customColor`: a raw colour code drawn in place of the item's own colours;
// `customRgbs`: four RGB values drawn in place of both
const clothingPreview = async (server, id, colorIndex, customColor, customRgbs) => {
  const def = (await defPack(server, DEF_ITEM)).get(Number(id));
  if (!def) throw new Error("The server does not know this item.");
  const colours = String(def.colors || "").split(",").filter(Boolean).map(c => Number(c) >>> 0);
  const custom = rawColour(customColor);
  const colour = custom !== null ? custom
    : colours[Math.min(Math.max(Number(colorIndex) || 0, 0), Math.max(colours.length - 1, 0))] || 0;
  let image = null;
  for (const iconId of CLOTHING_ICON_IDS) {
    const raw = await asset(server, `imageArrays/${((CLOTHING_AVATAR << 24) | (iconId << 16) | Number(def.layerDefId)) >>> 0}`);
    if (raw) {
      image = decodeAmf3(zlib.inflateSync(raw));
      break;
    }
  }
  if (!image || image.v !== IMAGE_ARRAY_VERSION || !image.f || !image.f[0]) {
    return { kind: "clothing", colors: colours.length, image: null };
  }
  const rgbs = rgbColours(customRgbs);
  const picture = paintFrame(image.f[0], rgbs ? rgbPalette(rgbs) : itemPalette(await gamePalette(server), colour));
  return {
    kind: "clothing",
    colors: colours.length,
    // each colour's code, so a shop colour can be picked up and changed
    codes: colours.map(String),
    swatches: await Promise.all(colours.map(async c => {
      const palette = await gamePalette(server);
      return [c >>> 24, c >>> 16, c >>> 8].map(i => `#${((palette[i & 0xff] || 0) & 0xffffff).toString(16).padStart(6, "0")}`);
    })),
    image: { width: picture.width, height: picture.height, rgba: picture.rgba.toString("base64") },
  };
};

// ------------------------------------------------------ den item preview --

// DenItem.getIconId
const denIconId = sortCat => {
  if ([0, 99, 6, 5].includes(sortCat)) return 1;
  if (sortCat === 1) return 2;
  if ([2, 3, 4].includes(sortCat)) return 3;
  return sortCat + 1;
};

// The den preview server: denPreview.swf, each item's SWF and the loader's
// report of the item's versions, on 127.0.0.1 and a port of the system's
// choosing. The loader reports over HTTP rather than to the page (with
// ExternalInterface), so an item SWF from the game server can never script
// the page.
const previewItems = new Map(); // token -> {swf, versions: null | number[] | "error"}
let previewServer = null;

const startPreviewServer = () => {
  if (!previewServer) {
    previewServer = new Promise((resolve, reject) => {
      const httpServer = http.createServer((req, res) => {
        const url = new URL(req.url, "http://127.0.0.1");
        const send = (status, type, body) => {
          res.writeHead(status, { "Content-Type": type, "Cache-Control": "no-store" });
          res.end(body);
        };
        if (req.method !== "GET") return send(405, "text/plain", "");
        // the page the finder frames: Flash only runs here when the page is
        // of the same origin as the SWF (a file:// page's embed never starts)
        if (url.pathname === "/view") {
          const token = String(url.searchParams.get("t") || "");
          const version = Math.min(Math.max(parseInt(url.searchParams.get("v"), 10) || 0, 0), 255);
          if (!/^[a-f0-9]{16}$/.test(token)) return send(400, "text/plain", "");
          return send(200, "text/html; charset=utf-8", "<!doctype html><html><head><meta charset=\"utf-8\"><style>html,body{margin:0;height:100%;overflow:hidden;background:transparent}embed{display:block;width:100%;height:100%}</style></head><body>"
            + `<embed type="application/x-shockwave-flash" src="/loader.swf?t=${token}&amp;v=${version}" wmode="transparent" scale="showall" quality="high" allowScriptAccess="never" allowNetworking="all" menu="false"></body></html>`);
        }
        if (url.pathname === "/loader.swf") {
          return fs.readFile(PREVIEW_LOADER, (err, body) => (err ? send(404, "text/plain", "") : send(200, "application/x-shockwave-flash", body)));
        }
        const item = /^\/item\/([a-f0-9]{16})\.swf$/.exec(url.pathname);
        if (item) {
          const entry = previewItems.get(item[1]);
          return entry ? send(200, "application/x-shockwave-flash", entry.swf) : send(404, "text/plain", "");
        }
        if (url.pathname === "/report") {
          const entry = previewItems.get(String(url.searchParams.get("t")));
          const versions = String(url.searchParams.get("versions") || "");
          if (entry) {
            entry.versions = versions === "error" ? "error"
              : versions.split(",").filter(v => /^\d{1,3}$/.test(v)).map(Number).filter(v => v <= 255).slice(0, 64);
          }
          return send(200, "text/plain", "ok");
        }
        send(404, "text/plain", "");
      });
      httpServer.on("error", err => {
        previewServer = null;
        reject(err);
      });
      httpServer.listen(0, "127.0.0.1", () => resolve(httpServer.address().port));
    });
  }
  return previewServer;
};

const denPreview = async (server, id) => {
  const def = (await defPack(server, DEF_DEN_ITEM)).get(Number(id));
  if (!def) throw new Error("The server does not know this den item.");
  const raw = await asset(server, `items/${((Number(id) << 16) | denIconId(Number(def.sortCat))) >>> 0}`);
  if (!raw) return { kind: "den", view: null };
  const wrapped = decodeAmf3(raw);
  const swf = wrapped && Buffer.isBuffer(wrapped.ba) ? wrapped.ba : null;
  if (!swf) return { kind: "den", view: null };
  const port = await startPreviewServer();
  const token = crypto.createHash("sha1").update(`${server}|${Number(id)}`).digest("hex").slice(0, 16);
  if (!previewItems.has(token)) {
    previewItems.set(token, { swf, versions: null });
    while (previewItems.size > MAX_PREVIEW_ITEMS) previewItems.delete(previewItems.keys().next().value);
  }
  return { kind: "den", view: `http://127.0.0.1:${port}/view?t=${token}`, token };
};

// the versions the loader found in a den item: null while it hasn't said yet
const denVersions = token => {
  const entry = previewItems.get(String(token));
  return entry ? entry.versions : "error";
};

// ------------------------------------------------------------- the calls --

const KINDS = ["all", "clothing", "den"];

const register = (ipcMain, serverUrl) => {
  const server = () => {
    const url = serverUrl();
    if (!url) throw new Error("Burrow isn't the selected server.");
    return url;
  };

  ipcMain.handle("burrow-items-search", async (event, { kind, query, username, token } = {}) => {
    try {
      const params = new URLSearchParams({
        kind: KINDS.includes(kind) ? kind : "all",
        q: String(query || "").slice(0, 60),
        username: String(username || ""),
        token: String(token || ""),
      });
      const response = await request(`${server()}/api/search?${params}`);
      if (response.status !== 200) return { error: `The item finder answered ${response.status}.` };
      const found = json(response);
      return { total: Number(found.total) || 0, results: Array.isArray(found.results) ? found.results : [] };
    }
    catch (err) {
      return { error: err.message };
    }
  });

  ipcMain.handle("burrow-items-give", async (event, { kind, id, colorIndex, color, username, token } = {}) => {
    try {
      const custom = kind === "clothing" ? rawColour(color) : null;
      const body = JSON.stringify(Object.assign(
        { kind, id: Number(id), colorIndex: Number(colorIndex) || 0, username, token },
        custom !== null ? { color: String(custom) } : {}));
      const response = await request(`${server()}/api/give`, { method: "POST", body });
      const answer = json(response);
      if (response.status === 403) return { error: "The server refused: log in again." };
      if (response.status !== 200) return { error: answer.error || `The server answered ${response.status}.` };
      return { ok: true, online: !!answer.online };
    }
    catch (err) {
      return { error: err.message };
    }
  });

  // the Burrow tab (gui/components/screens/BurrowTools.js)

  ipcMain.handle("burrow-status", async () => {
    try {
      const response = await request(`${server()}/api/status`);
      if (response.status !== 200) return { error: `The server answered ${response.status}.` };
      const status = json(response);
      return { online: Number(status.online) || 0, uptimeSeconds: Number(status.uptimeSeconds) || 0 };
    }
    catch (err) {
      return { error: err.message };
    }
  });

  ipcMain.handle("burrow-saved", async (event, { username, token } = {}) => {
    try {
      const params = new URLSearchParams({ username: String(username || ""), token: String(token || "") });
      const response = await request(`${server()}/api/saved?${params}`);
      if (response.status === 403) return { error: "The server refused: log in again." };
      if (response.status !== 200) return { error: `The server answered ${response.status}.` };
      const saved = json(response);
      return {
        outfits: Array.isArray(saved.outfits) ? saved.outfits.map(String) : [],
        layouts: Array.isArray(saved.layouts) ? saved.layouts.map(String) : [],
      };
    }
    catch (err) {
      return { error: err.message };
    }
  });

  // the outfit and den layout commands the server takes this way (its
  // /api/command): "!outfit wear NAME", "!den load NAME", "... savenew NAME",
  // "... off", "... undo"
  ipcMain.handle("burrow-command", async (event, { text, username, token } = {}) => {
    try {
      if (!/^!(outfit|den) (wear|load|savenew|off|undo)( [a-z0-9]{1,20})?$/.test(String(text))) {
        return { error: "Names are 1 to 20 lowercase letters and digits." };
      }
      const body = JSON.stringify({ text, username, token });
      const response = await request(`${server()}/api/command`, { method: "POST", body });
      const answer = json(response);
      if (response.status === 403) return { error: "The server refused: log in again." };
      if (response.status === 409) return { error: "Be in the game for that." };
      if (response.status !== 200) return { error: answer.error || `The server answered ${response.status}.` };
      return { ok: true };
    }
    catch (err) {
      return { error: err.message };
    }
  });

  ipcMain.handle("burrow-theme", async (event, { theme, username, token } = {}) => {
    try {
      const body = JSON.stringify({ theme: String(theme || ""), username, token });
      const response = await request(`${server()}/api/theme`, { method: "POST", body });
      const answer = json(response);
      if (response.status === 403) return { error: "The server refused: log in again." };
      if (response.status !== 200) return { error: answer.error || `The server answered ${response.status}.` };
      return { ok: true, theme: answer.theme };
    }
    catch (err) {
      return { error: err.message };
    }
  });

  // the game palette as "#rrggbb", for picking a custom colour's four parts
  ipcMain.handle("burrow-palette", async () => {
    try {
      return { colours: (await gamePalette(server())).map(c => `#${(c & 0xffffff).toString(16).padStart(6, "0")}`) };
    }
    catch (err) {
      return { error: err.message };
    }
  });

  ipcMain.handle("burrow-den-versions", async (event, { token } = {}) => ({ versions: denVersions(token) }));

  ipcMain.handle("burrow-items-preview", async (event, { kind, id, colorIndex, color, rgbs } = {}) => {
    try {
      if (kind === "clothing") return await clothingPreview(server(), id, colorIndex, color, rgbs);
      if (kind === "den") return await denPreview(server(), id);
      return { error: "Unknown item kind." };
    }
    catch (err) {
      return { error: err.message };
    }
  });
};

module.exports = { register, decodeAmf3, hashName, paintFrame, itemPalette, clothingPreview, denPreview, denVersions };
