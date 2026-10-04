"use strict";

(() => {
  window.AuthService = class AuthService {
    constructor(options = {}) {
      this.globals = options.globals || globals;
      this.showOtpModal = options.showOtpModal || showOtpModal;
      this.getDf = options.getDf || null;
      this.getGameData = options.getGameData || null;
      this.fetch = options.fetch || (this.globals && this.globals.fetch);
      this.config = options.config || (this.globals && this.globals.config);
    }

    isTokenExpired(token) {
      if (!token) return true
      const tokenParts = token.split('.')
      if (tokenParts.length !== 3) return false
      try {
        const payloadBase64 = tokenParts[1].replace(/-/g, '+').replace(/_/g, '/')
        const decodedJson = atob(payloadBase64)
        const decoded = JSON.parse(decodedJson)
        if (typeof decoded.exp !== 'number') return true
        const nowInSeconds = Date.now() / 1000
        return decoded.exp < (nowInSeconds + 30)
      } catch (e) {
        return true
      }
    }

    async authenticate(request, customDf, showOtpModalCallback) {
      const showOtp = showOtpModalCallback || this.showOtpModal;
      const getGameDataFunc = typeof this.getGameData === 'function' ? this.getGameData() : (this.getGameData || null);
      const fetch = this.fetch || (this.globals && this.globals.fetch);
      const config = this.config || (this.globals && this.globals.config);

      if (!fetch || !config) {
        throw new Error("AuthService: fetch or config not available");
      }

      request.domain = "flash";

      try {
        const freshDf = await window.ipc.getDf();

        if (freshDf && this.globals) {
          this.globals.df = freshDf;
        } else if (!freshDf) {
          console.warn("[AUTH] Failed to get fresh DF from main process");
        }
      } catch (err) {
        console.warn(`[AUTH] Error getting fresh df: ${err.message}`);
      }

      if (!this.globals || !this.globals.df) {
        console.error("[AUTH] No valid DF available, authentication may fail");
      }

      const dfToUse = customDf || (this.globals ? this.globals.df : null);
      request.df = dfToUse;

      // Build headers with Origin, Referer, User-Agent, and Accept to match server expectations
      const authHeaders = {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };
      
      // Add Origin and Referer headers if config.origin is available
      if (config.origin) {
        authHeaders["Origin"] = config.origin;
        authHeaders["Referer"] = `${config.origin}/game/play`;
      }
      
      // Add User-Agent to match expected format
      authHeaders["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) AJClassic/1.5.7 Chrome/87.0.4280.141 Electron/11.5.0 Safari/537.36";

      const response = await fetch(`${config.authenticator}/authenticate`, {
        method: "POST",
        mode: "cors",
        cache: "no-store",
        headers: authHeaders,
        body: JSON.stringify(request),
      }, [401, 403, 422, 500]);

      if (response.status === 200) {
        const authenticateData = JSON.parse(await response.text());
        const authenticatedByToken = (request.refresh_token !== undefined);
        if (getGameDataFunc) {
          return await getGameDataFunc(authenticateData, authenticatedByToken, dfToUse);
        } else {
          return authenticateData;
        }
      }

      if (response.status === 401) {
        let authError = {};
        try {
          authError = JSON.parse(await response.text());
        } catch (parseErr) {
          console.error("[AUTH] Error parsing 401 response:", parseErr);
        }

        const errorText = (authError.error || authError.message || '').toLowerCase();
        const errorCode = authError.error_code;

        if (errorText.includes('otp') ||
            errorText.includes('two') ||
            errorText.includes('2fa') ||
            errorText.includes('verification') ||
            errorCode === 'otp_required' ||
            errorCode === 'two_factor_required') {
          if (showOtp) showOtp();
          throw new Error("OTP_NEEDED");
        }

        switch (authError.error_code) {
          case 100: throw new Error("REFRESH_TOKEN_EXPIRED");
          case 101: throw new Error("WRONG_CREDENTIALS");
          case 102: throw new Error("BANNED");
          case 103: throw new Error("SUSPENDED");
          default: throw new Error("LOGIN_ERROR");
        }
      }

      if (response.status === 422) {
        let otpNeeded = false;
        try {
          const responseText = await response.text();
          const authError = JSON.parse(responseText);
          if (authError.error == "invalid_otp" || authError.error == "pending_otp_confirmation") {
            otpNeeded = true;
          }
        } catch (parseErr) {
          console.error("[AUTH] Error parsing 422 response:", parseErr);
        }

        if (otpNeeded) {
          if (showOtp) showOtp();
          throw new Error("OTP_NEEDED");
        }
        throw new Error("LOGIN_ERROR");
      }

      if (response.status === 403) {
        try {
          const responseText = await response.text();
          
          if (responseText) {
            try {
              const errorData = JSON.parse(responseText);
              const errorText = (errorData.error || errorData.message || '').toLowerCase();
              
              if (errorText.includes('rate') || errorText.includes('limit') || errorText.includes('too many')) {
                throw new Error("RATE_LIMITED");
              }
            } catch (parseErr) {
            }
          }
          
          const rateLimitRemaining = response.headers.get('X-RateLimit-Remaining');
          
          if (rateLimitRemaining === '0' || rateLimitRemaining === null) {
            throw new Error("RATE_LIMITED");
          }
          
          console.error("[AUTH] 403 Forbidden - possible IP block or missing permissions");
          throw new Error("LOGIN_ERROR");
        } catch (err) {
          if (err.message === "RATE_LIMITED" || err.message === "LOGIN_ERROR") {
            throw err;
          }
          console.error("[AUTH] Could not parse 403 response:", err);
          throw new Error("LOGIN_ERROR");
        }
      }

      console.error("[AUTH] Unexpected response status:", response.status);

      let otpNeeded = false;
      try {
        const responseText = await response.text();
        const errorData = JSON.parse(responseText);
        const errorText = (errorData.error || errorData.message || '').toLowerCase();

        otpNeeded = errorText.includes('otp') ||
            errorText.includes('two') ||
            errorText.includes('2fa') ||
            errorText.includes('verification');
      } catch (parseErr) {
        console.error("[AUTH] Could not parse response body:", parseErr);
      }

      if (otpNeeded) {
        if (showOtp) showOtp();
        throw new Error("OTP_NEEDED");
      }
      throw new Error("ERROR");
    }

    async authenticateWithAuthToken(authToken, showOtpModalCallback) {
      const request = {auth_token: authToken};
      try {
        const result = await this.authenticate(request, null, showOtpModalCallback);
        return result;
      } catch (err) {
        console.error("[AUTH] Token validation failed:", err.message);
        throw err;
      }
    }

    async authenticateWithRefreshToken(refreshToken, otp, showOtpModalCallback) {
      const request = {refresh_token: refreshToken};
      if (otp) {
        request.otp = otp;
      }
      return await this.authenticate(request, null, showOtpModalCallback);
    }

    async authenticateWithPassword(username, password, otp, customDf, showOtpModalCallback) {
      const request = {username, password};
      if (otp) {
        request.otp = otp;
      }
      return await this.authenticate(request, customDf, showOtpModalCallback);
    }
  };
})();
