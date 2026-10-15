"use strict";

// Logging in to a Burrow private server (https://github.com/burrow-dev/burrow-server)
// instead of Animal Jam, when Strawberry Jam's Burrow mode is on.
//
// Burrow answers the same calls the official launcher makes (/flashvars,
// /authenticate, /player, /gameClient/game/index.html), so this mirrors what
// Burrow's own client does (its app/index.html logIn), except that the game
// socket goes to Strawberry Jam's proxy, which relays it to the server
// (src/services/network/GameServerTarget.js), so plugins see the traffic.
//
// The game client is Strawberry Jam's modded SWF unless the launcher's Burrow
// settings pick the server's own: Burrow's login takes the official client,
// and both are built for the same deploy. With ours, the game's content comes
// through the local API's asset proxy, which follows the server too.
//
// Nothing that belongs to the Animal Jam login is sent to a Burrow server:
// no device fingerprint (df), no saved AJ tokens.
(() => {
  const ERROR_MESSAGES = {
    captcha_required: "Complete the captcha.",
    captcha_failed: "Captcha failed. Try again.",
    captcha_unavailable: "Captcha unavailable. Try again later.",
    totp_wrong: "Wrong 2FA code.",
    account_locked: "This Burrow account is locked.",
    rename_expired: "Log in again.",
    too_many_attempts: "Too many attempts. Try again later.",
  };

  // after a passed captcha the server hands out a pass, good for the next
  // try with the same account (its lib/captcha.js)
  let captchaPass = null; // {server, username, pass}

  const burrowError = message => Object.assign(new Error(message), { burrowMessage: message });

  const getJson = async (url, options) => {
    let response;
    try {
      response = await window.fetch(url, Object.assign({ cache: "no-store" }, options));
    } catch (err) {
      throw burrowError(`Couldn't reach the Burrow server at ${new URL(url).origin}.`);
    }
    let body = {};
    try {
      body = await response.json();
    } catch (_) {
      // an error page; the status says enough
    }
    return { status: response.status, body };
  };

  const formatBan = seconds => {
    if (seconds < 0) return "for good";
    const hours = Math.ceil(seconds / 3600);
    return hours >= 48 ? `for ${Math.ceil(hours / 24)} more days` : `for ${hours} more hours`;
  };

  window.BurrowAuth = {
    // {url, client} for the selected Burrow server, or null for Animal Jam
    async target() {
      try {
        const target = await window.ipc.invoke("get-game-server-target");
        return target && target.server === "burrow" ? { url: target.url, client: target.client || "strawberry" } : null;
      } catch (_) {
        return null;
      }
    },

    // the Burrow server's base URL, or null when the game goes to Animal Jam
    async serverUrl() {
      const target = await this.target();
      return target ? target.url : null;
    },

    // resolves to {userData, flashVars, gamePageUrl}; throws an Error whose
    // burrowMessage is shown to the player, or OTP_NEEDED after asking for a code.
    async logIn(target, username, password, otp, showOtpModal) {
      const server = target.url;
      const flashVars = (await getJson(`${server}/flashvars?_=${Date.now()}`)).body;
      if (!flashVars || !flashVars.clientURL) {
        throw burrowError(`${server} is not a Burrow server.`);
      }

      const lowerName = username.toLowerCase();
      const request = {
        username,
        password,
        domain: "flash",
        totp: otp || undefined,
        captcha_pass: captchaPass && captchaPass.server === server && captchaPass.username === lowerName ? captchaPass.pass : undefined,
      };
      const authenticate = body => getJson(`${server}/authenticate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      let auth = await authenticate(request);
      if (auth.body.error === "captcha_required") {
        const answer = await window.ipc.invoke("burrow-captcha", "login");
        if (!answer) throw burrowError(ERROR_MESSAGES.captcha_required);
        auth = await authenticate(Object.assign({}, request, { captcha: answer, captcha_pass: undefined }));
      }
      captchaPass = auth.body.captcha_pass ? { server, username: lowerName, pass: auth.body.captcha_pass } : null;

      const error = auth.body.error;
      if (auth.status === 401 && error === "totp_required") {
        showOtpModal();
        throw new Error("OTP_NEEDED");
      }
      if (ERROR_MESSAGES[error]) throw burrowError(ERROR_MESSAGES[error]);
      if (auth.status === 401 && (error === "account_banned" || error === "address_banned")) {
        const reason = auth.body.ban_reason ? ` Reason: ${auth.body.ban_reason}` : "";
        const seconds = error === "address_banned" ? -1 : Number(auth.body.banned_seconds);
        throw burrowError(`Banned from Burrow ${formatBan(seconds)}.${reason}`);
      }
      if (auth.status === 401 && error === "name_rejected") {
        throw burrowError(`Burrow rejected this username. Pick a new one at ${server}/account, then log in again.`);
      }
      if (auth.status === 401) throw burrowError("Wrong Burrow username or password.");
      if (auth.status === 429) throw burrowError(ERROR_MESSAGES.too_many_attempts);
      if (auth.status !== 200 || !auth.body.auth_token) {
        throw burrowError(`The Burrow server refused the login (${auth.status}).`);
      }

      const player = await getJson(`${server}/player`, {
        headers: { Authorization: `Bearer ${auth.body.auth_token}` },
      });
      if (player.status !== 200) {
        throw burrowError(`The Burrow server refused the login (${player.status}).`);
      }

      const serverPort = await window.ipc.invoke("get-server-port").catch(() => null);
      if (!serverPort) {
        throw burrowError("Connection server is not running. Please restart the application.");
      }

      // the game socket comes to the proxy either way. Burrow's own client
      // keeps its web side (content, its SWF, the wall, masterpieces) on the
      // server, which only lets that game load from its own address; ours gets
      // them from the local API, as it does on Animal Jam.
      const ownClient = target.client === "burrow";
      if (!ownClient) {
        const apiPort = await globals.getRequiredApiPort();
        Object.assign(flashVars, {
          content: `http://localhost:${apiPort}/`,
          clientURL: `http://localhost:${apiPort}/${flashVars.deploy_version}/ajclient.swf?t=${Date.now()}`,
          playerWallHost: `http://localhost:${apiPort}/wall`,
          mdUrl: `http://localhost:${apiPort}/game/`,
        });
      }
      delete flashVars.loginChoices;
      delete flashVars.membershipChoice;
      Object.assign(flashVars, globals.getClientData(), {
        smartfoxServer: "127.0.0.1",
        smartfoxPort: String(serverPort),
        auth_token: auth.body.auth_token,
        df: "private-client",
        locale: "en",
        username: player.body.screen_name,
        webRefPath: "game/play",
      });

      return {
        userData: {
          username: player.body.screen_name,
          accountType: player.body.game_account_type,
          language: player.body.language || "en",
          authToken: auth.body.auth_token,
        },
        flashVars,
        server,
        // Burrow's own client runs in its own game page; ours in the usual one
        gamePageUrl: ownClient ? `${server}/gameClient/game/index.html` : null,
      };
    },
  };

  // A banner over the login screen while Burrow is picked, so an Animal Jam
  // password is not typed in for the wrong server by mistake.
  const banner = document.createElement("div");
  banner.id = "burrow-banner";
  banner.style.cssText = [
    "position:fixed", "top:0", "left:50%", "transform:translateX(-50%)", "z-index:2147483646",
    "padding:6px 14px", "border-radius:0 0 10px 10px", "background:#2b1d14", "color:#f7d9a8",
    "font:600 13px/1.3 sans-serif", "box-shadow:0 2px 8px rgba(0,0,0,.35)", "pointer-events:none", "display:none",
  ].join(";");

  const refreshBanner = async () => {
    const server = await window.BurrowAuth.serverUrl();
    const loginScreen = document.getElementById("login-screen");
    const loggedIn = !loginScreen || loginScreen.classList.contains("in-game");
    banner.textContent = server ? `Burrow mode: logging in to ${new URL(server).host} (switch back with AJ / Burrow next to PLAY)` : "";
    banner.style.display = server && !loggedIn ? "block" : "none";
  };

  window.addEventListener("DOMContentLoaded", () => {
    document.body.appendChild(banner);
    refreshBanner();
    setInterval(refreshBanner, 3000);
  });
  window.addEventListener("focus", refreshBanner);
})();
