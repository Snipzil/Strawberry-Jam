(() => {
  const TEMPLATE = `

        <style>
          /* ------------------------------------------------------------
             Theme tokens
             --theme-* values are driven by LoginScreen.theme-manager.js.
             --sj-* values are derived surface/text tokens used by this
             template; they flip for dark mode via :host(.dark-mode).
             ------------------------------------------------------------ */
          :host {
            --theme-primary: #e83d52;
            --theme-secondary: rgba(232, 61, 82, 0.3);
            --theme-highlight: rgba(255, 220, 220, 0.3);
            --theme-shadow: rgba(252, 93, 93, 0.1);
            --theme-gradient-start: rgba(255, 220, 220, 0.3);
            --theme-gradient-end: rgba(255, 245, 230, 0.6);
            --theme-hover-border: rgba(232, 61, 82, 0.5);
            --theme-radial-1: rgba(255, 180, 180, 0.05);
            --theme-radial-2: rgba(255, 200, 200, 0.07);
            --theme-settings-hover: rgba(232, 61, 82, 0.05);
            --theme-settings-border: rgba(232, 61, 82, 0.2);
            --theme-box-background: rgba(45, 45, 45, 0.95);
            --theme-box-background-dark: rgba(26, 26, 30, 0.96);
            --theme-box-background-light: rgba(255, 247, 236, 0.96);
            --theme-button-bg: var(--theme-primary);
            --theme-button-border: var(--theme-secondary);
            --theme-button-text: #FFFFFF;
            --dark-mode: 0;

            --sj-font: 'CCDigitalDelivery', 'Segoe UI', 'Roboto', sans-serif;
            --sj-display: 'Tiki-Island', 'CCDigitalDelivery', 'Segoe UI', sans-serif;

            /* light-mode surface tokens (default) */
            --sj-surface: var(--theme-box-background);
            --sj-surface-elev: rgba(255, 255, 255, 0.65);
            --sj-text: #553b2c;
            --sj-text-muted: #8a6d5b;
            --sj-text-faint: rgba(85, 59, 44, 0.5);
            --sj-border: rgba(85, 59, 44, 0.14);
            --sj-border-strong: rgba(85, 59, 44, 0.24);
            --sj-input-bg: rgba(255, 255, 255, 0.55);
            --sj-input-text: #4a3325;
            --sj-input-placeholder: rgba(85, 59, 44, 0.45);
            --sj-control-bg: rgba(85, 59, 44, 0.07);
            --sj-toggle-off: rgba(85, 59, 44, 0.28);
            --sj-shadow: 0 24px 60px rgba(0, 0, 0, 0.35), 0 8px 32px var(--theme-shadow);
            --sj-radius-lg: 22px;
            --sj-radius: 12px;

            width: 100%;
            height: 100%;
            display: grid;
            grid-template: 1fr min(590px, 80%) 1fr / 1fr min(70px, 8%) min(936px, 75%) 1fr;
            grid-template-areas: ". . . button-tray"
                                 ". panel box ."
                                 ". . . .";
            background-color: rgba(239, 234, 221, 0);
            background-image:
              radial-gradient(900px circle at 12% 8%, var(--theme-shadow) 0%, transparent 60%),
              radial-gradient(700px circle at 92% 95%, var(--theme-radial-2) 0%, transparent 60%);
            transition: background-color 0.2s;
            font-family: var(--sj-font);
            /* keep internal z-indexes (card, panels) from escaping above #modal-layer */
            isolation: isolate;

            opacity: 0;
            visibility: hidden;
            transition: opacity 0.3s ease-out;
          }

          :host(.theme-ready) {
            opacity: 1;
            visibility: visible;
          }

          :host(.dark-mode) {
            --sj-surface: var(--theme-box-background-dark);
            --sj-surface-elev: rgba(255, 255, 255, 0.08);
            --sj-text: #ECECEE;
            --sj-text-muted: #A6A6AE;
            --sj-text-faint: rgba(236, 236, 238, 0.45);
            --sj-border: rgba(255, 255, 255, 0.08);
            --sj-border-strong: rgba(255, 255, 255, 0.24);
            --sj-input-bg: rgba(255, 255, 255, 0.06);
            --sj-input-text: #F3F3F5;
            --sj-input-placeholder: rgba(255, 255, 255, 0.38);
            --sj-control-bg: rgba(255, 255, 255, 0.05);
            --sj-toggle-off: rgba(255, 255, 255, 0.18);
            --sj-shadow: 0 24px 60px rgba(0, 0, 0, 0.55), 0 8px 32px var(--theme-shadow);
          }

          /* While the game is showing, lift only the utility controls above the
             game screen; everything else on the login screen is hidden. */
          :host(.in-game) {
            position: relative;
            z-index: 2;
            pointer-events: none;
            background-image: none;
          }

          :host(.in-game) #box,
          :host(.in-game) #box-background,
          :host(.in-game) #account-panel-instance,
          :host(.in-game) #glockoma-credit,
          :host(.in-game) #login-help-prompt,
          :host(.in-game) #import-section,
          :host(.in-game) #auto-wheel-section,
          :host(.in-game) #button-tray {
            visibility: hidden;
          }

          :host(.in-game) .icon-button,
          :host(.in-game) #settings-panel.show,
          :host(.in-game) #version {
            pointer-events: auto;
          }

          *, *::before, *::after {
            box-sizing: border-box;
          }

          .hidden {
            display: none !important;
          }

          /* ------------------------------------------------------------
             Login card
             ------------------------------------------------------------ */
          #box-background {
            grid-area: box;
            position: relative;
            z-index: 0;
            background-color: var(--sj-surface);
            border-radius: var(--sj-radius-lg);
            box-shadow: var(--sj-shadow);
            border: 1px solid var(--theme-secondary);
            opacity: 1;
            transition: opacity 0.2s, box-shadow 0.3s ease, border-color 0.3s ease, background-color 0.3s ease;
            will-change: background-color;
            overflow: hidden;
          }

          #box-background::before {
            content: '';
            position: absolute;
            inset: 0;
            pointer-events: none;
            background:
              linear-gradient(180deg, rgba(255, 255, 255, 0.18) 0%, rgba(255, 255, 255, 0) 38%),
              radial-gradient(circle at 12% 18%, var(--theme-radial-1) 0%, transparent 50%),
              radial-gradient(circle at 88% 82%, var(--theme-radial-2) 0%, transparent 50%);
          }

          #box-background::after {
            content: '';
            position: absolute;
            left: 0;
            right: 0;
            top: 0;
            height: 3px;
            background: linear-gradient(90deg, transparent 0%, var(--theme-primary) 35%, var(--theme-primary) 65%, transparent 100%);
            opacity: 0.9;
            pointer-events: none;
          }

          :host(.dark-mode) #box-background {
            background-color: var(--theme-box-background-dark);
          }

          :host(.dark-mode) #box-background::before {
            background:
              linear-gradient(180deg, rgba(255, 255, 255, 0.05) 0%, rgba(255, 255, 255, 0) 38%),
              radial-gradient(circle at 12% 18%, var(--theme-radial-1) 0%, transparent 50%),
              radial-gradient(circle at 88% 82%, var(--theme-radial-2) 0%, transparent 50%);
          }

          #box {
            grid-area: box;
            position: relative;
            z-index: 1;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 44px 64px;
            border-radius: var(--sj-radius-lg);
          }

          #login-container {
            display: flex;
            flex-direction: column;
            align-items: center;
            width: 300px;
            max-width: 100%;
          }

          #login-container > * {
            margin-bottom: 9px;
          }

          #login-app-icon {
            width: 88px !important;
            height: 88px;
            object-fit: contain;
            display: block;
            margin: 0 auto 6px auto !important;
            filter: drop-shadow(0 10px 18px rgba(0, 0, 0, 0.28));
            transition: transform 0.25s cubic-bezier(0.34, 1.56, 0.64, 1);
          }

          #login-app-icon:hover {
            transform: translateY(-2px) scale(1.04);
          }

          #player-login-text {
            color: var(--theme-primary);
            font-family: var(--sj-display);
            font-size: 36px;
            line-height: 1.05;
            text-shadow: 1px 2px 0px var(--theme-shadow);
            margin-bottom: 18px;
            letter-spacing: 0.5px;
            text-align: center;
            transition: color 0.3s ease, text-shadow 0.3s ease;
          }

          ajd-text-input {
            width: 100%;
            border-radius: 14px;
            border: 1.5px solid var(--sj-border);
            background-color: var(--sj-input-bg);
            transition: border-color 0.2s ease, box-shadow 0.2s ease, background-color 0.2s ease;
            margin-bottom: 12px;
            --ajd-input-radius: 14px;
          }

          ajd-text-input:hover {
            border-color: var(--theme-hover-border);
          }

          ajd-text-input:focus-within {
            border-color: var(--theme-primary);
            box-shadow: 0 0 0 3px var(--theme-shadow), 0 6px 18px rgba(0, 0, 0, 0.12);
          }

          #remember-me-cb {
            font-size: 15px;
            letter-spacing: -0.5px;
            font-weight: bold;
            align-self: flex-start;
            margin-left: 4px;
            margin-bottom: 14px;
            color: var(--sj-text);
          }

          #login-btn-container {
            display: grid;
            grid-template-columns: 1fr;
            justify-items: center;
            position: relative;
            width: 100%;
          }

          #log-in-btn {
            padding: 6px 28px;
            min-width: 168px;
            text-align: center;
            --ajd-bubble-button-background-color: var(--theme-button-bg);
            --ajd-bubble-button-border-color: var(--theme-button-border);
            --ajd-bubble-button-text-color: var(--theme-button-text);
            transition: background-color 0.3s ease, border-color 0.3s ease, color 0.3s ease;
          }

          #forgot-password-link {
            font-size: 12px;
            line-height: 14px;
            letter-spacing: 0;
            color: var(--sj-text-muted);
            text-decoration: none;
            user-select: none;
            cursor: pointer;
            font-family: var(--sj-font);
            padding: 2px 6px;
            border-radius: 6px;
            transition: color 0.15s ease, background-color 0.15s ease;
          }

          #forgot-password-link:hover {
            color: var(--theme-primary);
            text-decoration: none;
            background-color: var(--theme-settings-hover);
          }

          .vertical-spacer {
            height: 1px;
            width: 80%;
            border-bottom: none;
            background: linear-gradient(90deg, transparent, var(--theme-secondary), transparent);
            margin: 12px 0 10px;
            transition: background 0.3s ease;
          }

          #need-account {
            user-select: none;
            pointer-events: none;
            font-size: 11px;
            line-height: 16px;
            letter-spacing: 0.04em;
            text-transform: uppercase;
            color: var(--sj-text-faint);
            font-family: var(--sj-font);
            font-weight: bold;
          }

          #create-account-btn {
            font-size: 22px;
            padding: 4px 16px;
            --ajd-bubble-button-background-color: var(--theme-button-bg);
            --ajd-bubble-button-border-color: var(--theme-button-border);
            --ajd-bubble-button-text-color: var(--theme-button-text);
            transition: background-color 0.3s ease, border-color 0.3s ease, color 0.3s ease;
          }

          @keyframes fade {
            0%,100% { opacity: 0 }
            50% { opacity: 1 }
          }

          @keyframes spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(-360deg); }
          }

          @keyframes fruit-pop {
            0%   { transform: scale(1); }
            50%  { transform: scale(1.25); }
            100% { transform: scale(1); }
          }

          .fruit-animate {
            animation: fruit-pop 0.3s ease-out;
            transform-style: preserve-3d;
          }

          #spinner {
            position: absolute;
            left: calc(50% + 96px);
            top: 50%;
            transform: translateY(-50%);
            height: 24px;
            opacity: 0;
            transition: opacity .5s;
            animation: spin 1500ms linear infinite;
            cursor: pointer;
          }

          #spinner.show {
            opacity: 1;
          }

          /* ------------------------------------------------------------
             Bottom-left utility buttons (settings / debug logs)
             ------------------------------------------------------------ */
          .button-container-bottom-left {
            position: absolute;
            bottom: 12px;
            left: 12px;
            display: flex;
            flex-direction: column;
            gap: 8px;
            z-index: 1000;
            pointer-events: none;
          }

          .icon-button {
            width: 34px;
            height: 34px;
            min-width: 34px;
            max-width: 34px;
            min-height: 34px;
            max-height: 34px;
            font-size: 16px;
            border: 1px solid var(--sj-border-strong);
            border-radius: 10px;
            background-color: var(--sj-surface);
            color: var(--sj-text);
            cursor: pointer;
            opacity: 1;
            transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1), border-color 0.2s ease, color 0.2s ease, box-shadow 0.2s ease, opacity 0.2s ease;
            display: flex;
            align-items: center;
            justify-content: center;
            pointer-events: auto;
            overflow: hidden;
            margin: 0;
            padding: 0;
            position: relative;
            flex-shrink: 0;
            outline: none;
            line-height: 1;
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.25);
            backdrop-filter: blur(8px);
          }

          .icon-button:hover {
            opacity: 1;
            color: var(--theme-primary);
            border-color: var(--theme-hover-border);
            transform: translateY(-1px);
            box-shadow: 0 6px 18px rgba(0, 0, 0, 0.3), 0 0 0 3px var(--theme-shadow);
          }

          .icon-button:active {
            transform: translateY(0) scale(0.96);
          }

          .icon-button svg {
            display: block;
            width: 16px;
            height: 16px;
            color: currentColor;
          }

          #settings-btn svg {
            transition: transform 0.4s ease;
          }

          #settings-btn:hover svg {
            transform: rotate(60deg);
          }

          #devtools-btn-wrapper {
            position: relative;
            display: inline-block;
            contain: layout style;
            overflow: visible;
          }

          #devtools-error-badge {
            position: absolute;
            top: -6px;
            right: -6px;
            background-color: #e74c3c;
            color: white;
            border-radius: 999px;
            min-width: 18px;
            height: 18px;
            display: none;
            align-items: center;
            justify-content: center;
            font-size: 10px;
            font-weight: bold;
            line-height: 1;
            padding: 0 4px;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.4), 0 0 0 2px var(--sj-surface);
            pointer-events: none;
            z-index: 1000;
            will-change: transform;
            animation: badge-pulse 2s ease-in-out infinite;
            font-family: var(--sj-font);
          }

          #devtools-error-badge.show {
            display: flex;
          }

          @keyframes badge-pulse {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.1); }
          }

          /* ------------------------------------------------------------
             Settings panel
             ------------------------------------------------------------ */
          #settings-panel {
            position: absolute;
            bottom: 98px;
            left: 12px;
            width: 272px;
            background-color: var(--sj-surface);
            border: 1px solid var(--sj-border-strong);
            border-radius: 16px;
            padding: 14px;
            padding-right: 8px;
            z-index: 999;
            box-shadow: var(--sj-shadow);
            transition: border-color 0.3s ease, box-shadow 0.3s ease, max-height 0.3s cubic-bezier(0.34, 1.56, 0.64, 1), opacity 0.3s ease;
            contain: layout style;
            backdrop-filter: blur(14px);
            font-family: var(--sj-font);
            color: var(--sj-text);

            max-height: 0;
            overflow: hidden;
            overflow-y: auto;
            opacity: 0;
            transform-origin: bottom left;
            pointer-events: none;
          }

          #settings-panel::-webkit-scrollbar {
            width: 6px;
          }

          #settings-panel::-webkit-scrollbar-track {
            background: transparent;
            border-radius: 10px;
          }

          #settings-panel::-webkit-scrollbar-thumb {
            background-color: var(--theme-secondary);
            border-radius: 10px;
          }

          #settings-panel::-webkit-scrollbar-thumb:hover {
            background-color: var(--theme-primary);
          }

          .settings-item-ingame {
            display: none;
          }

          :host(.in-game) .settings-item-ingame {
            display: flex;
          }

          #settings-panel.show {
            min-height: min(470px, calc(100vh - 112px));
            max-height: min(600px, calc(100vh - 112px));
            opacity: 1;
            animation: slideUp 0.3s ease forwards;
            pointer-events: auto;
          }

          @keyframes slideUp {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
          }

          #settings-panel h3 {
            margin: 0 0 10px 0;
            color: var(--theme-primary);
            font-family: var(--sj-display);
            font-size: 18px;
            text-align: left;
            padding-left: 4px;
            letter-spacing: 0.3px;
            text-shadow: 1px 1px 0px var(--theme-shadow);
            transition: color 0.3s ease, text-shadow 0.3s ease;
            overflow: hidden;
            word-wrap: break-word;
            max-width: 100%;
          }

          #settings-panel * {
            box-sizing: border-box;
            max-width: 100%;
          }

          #settings-panel h4, #settings-panel h5,
          #settings-panel label, #settings-panel select {
            overflow: hidden;
            word-wrap: break-word;
            max-width: 100%;
          }

          .settings-tabs {
            display: flex;
            gap: 2px;
            margin-bottom: 12px;
            padding: 3px;
            border-radius: 10px;
            background-color: var(--sj-control-bg);
            border: none;
          }

          .settings-tab {
            flex: 1;
            padding: 6px 8px;
            background-color: transparent;
            border: none;
            border-radius: 8px;
            color: var(--sj-text-muted);
            font-family: var(--sj-font);
            font-size: 11px;
            font-weight: bold;
            letter-spacing: 0.02em;
            cursor: pointer;
            transition: background-color 0.2s ease, color 0.2s ease, box-shadow 0.2s ease;
            outline: none !important;
            box-shadow: none !important;
            -webkit-tap-highlight-color: transparent;
            user-select: none;
            -webkit-user-select: none;
          }

          .settings-tab:focus,
          .settings-tab:focus-visible,
          .settings-tab:active,
          .settings-tab:focus-within {
            outline: none !important;
            -webkit-tap-highlight-color: transparent;
          }

          .settings-tab:hover {
            color: var(--theme-primary);
            background-color: var(--theme-settings-hover);
          }

          .settings-tab.active {
            color: var(--theme-primary);
            background-color: var(--sj-surface-elev);
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.12) !important;
          }

          .settings-tab-content {
            display: none;
          }

          .settings-tab-content.active {
            display: block;
          }

          .settings-group {
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 1px solid var(--theme-settings-border);
            transition: border-bottom-color 0.3s ease;
          }

          .settings-group:last-child {
            border-bottom: none;
            margin-bottom: 0;
            padding-bottom: 0;
          }

          .settings-subsection {
            margin-bottom: 10px;
            padding-bottom: 8px;
            border-bottom: 1px solid var(--sj-border);
          }

          .settings-subsection:last-child {
            border-bottom: none;
            margin-bottom: 0;
            padding-bottom: 0;
          }

          .settings-subsection h5 {
            font-family: var(--sj-font);
            color: var(--sj-text-faint);
            font-size: 9.5px;
            margin: 0 0 4px 0;
            padding-left: 8px;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            font-weight: bold;
          }

          .settings-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 2px;
            font-size: 12px;
            color: var(--sj-text);
            font-family: var(--sj-font);
            padding: 6px 8px;
            transition: background-color 0.15s;
            border-radius: 8px;
            max-width: 100%;
            flex-wrap: wrap;
            gap: 6px;
          }

          .settings-item:hover {
            background-color: var(--theme-settings-hover);
          }

          .settings-item > span:first-child {
            flex: 1;
            min-width: 0;
          }

          .settings-shortcut {
            font-size: 11px;
            color: var(--sj-text-muted);
            padding: 4px 8px;
            display: flex;
            align-items: center;
            border-radius: 6px;
          }

          .settings-shortcut kbd {
            display: inline-block;
            font-family: var(--sj-font);
            font-size: 10px;
            line-height: 1;
            padding: 3px 6px;
            margin-right: 8px;
            border-radius: 5px;
            background: var(--sj-control-bg);
            border: 1px solid var(--sj-border-strong);
            color: var(--sj-text);
            white-space: nowrap;
            box-shadow: 0 1px 0 var(--sj-border-strong);
          }

          .settings-toggle {
            width: 38px;
            height: 21px;
            background: var(--sj-toggle-off);
            border-radius: 11px;
            position: relative;
            cursor: pointer;
            transition: background-color 0.2s ease, box-shadow 0.2s ease;
            flex-shrink: 0;
          }

          .settings-toggle::after {
            content: '';
            position: absolute;
            width: 17px;
            height: 17px;
            background: white;
            border-radius: 50%;
            top: 2px;
            left: 2px;
            transition: transform 0.22s cubic-bezier(0.34, 1.56, 0.64, 1);
            box-shadow: 0 1px 3px rgba(0, 0, 0, 0.35);
          }

          .settings-peer:checked ~ .settings-toggle {
            background-color: var(--theme-primary, #e83d52);
            box-shadow: 0 0 0 3px var(--theme-shadow);
          }

          .settings-peer:checked ~ .settings-toggle::after {
            transform: translateX(17px);
          }

          .settings-peer:focus-visible ~ .settings-toggle {
            box-shadow: 0 0 0 3px var(--theme-secondary);
          }

          .sr-only {
            position: absolute;
            width: 1px;
            height: 1px;
            padding: 0;
            margin: -1px;
            overflow: hidden;
            clip: rect(0,0,0,0);
            border: 0;
          }

          .settings-select,
          .settings-input {
            font-family: var(--sj-font);
            font-size: 11px;
            color: var(--sj-input-text);
            background-color: var(--sj-input-bg);
            border: 1px solid var(--sj-border-strong);
            border-radius: 8px;
            padding: 5px 8px;
            outline: none;
            transition: border-color 0.15s ease, box-shadow 0.15s ease;
            color-scheme: light;
          }

          :host(.dark-mode) .settings-select,
          :host(.dark-mode) .settings-input {
            color-scheme: dark;
          }

          .settings-select {
            padding-right: 22px;
            appearance: none;
            -webkit-appearance: none;
            background-image: linear-gradient(45deg, transparent 50%, currentColor 50%), linear-gradient(135deg, currentColor 50%, transparent 50%);
            background-position: calc(100% - 12px) 55%, calc(100% - 8px) 55%;
            background-size: 4px 4px, 4px 4px;
            background-repeat: no-repeat;
            cursor: pointer;
          }

          .settings-select:hover,
          .settings-input:hover {
            border-color: var(--theme-hover-border);
          }

          .settings-select:focus,
          .settings-input:focus {
            border-color: var(--theme-primary);
            box-shadow: 0 0 0 3px var(--theme-shadow);
          }

          .settings-input::placeholder {
            color: var(--sj-input-placeholder);
          }

          .settings-input-full {
            width: 100%;
          }

          .settings-field {
            margin-bottom: 8px;
          }

          .settings-field-label {
            display: block;
            font-size: 10.5px;
            margin-bottom: 4px;
            color: var(--sj-text-muted);
            font-family: var(--sj-font);
            padding-left: 2px;
          }

          #custom-theme-color-container {
            margin: 4px 0 0 0;
            padding: 10px;
            background-color: var(--sj-control-bg);
            border: 1px solid var(--sj-border);
            border-radius: 10px;
            opacity: 0.5;
            pointer-events: none;
            transition: opacity 0.2s ease;
          }

          .settings-color-row {
            display: flex;
            align-items: center;
            gap: 6px;
            margin-bottom: 8px;
          }

          #custom-theme-color-picker {
            width: 40px;
            height: 30px;
            min-width: 40px;
            flex-shrink: 0;
            border: 1px solid var(--sj-border-strong);
            border-radius: 8px;
            cursor: pointer;
            padding: 2px;
            background: var(--sj-input-bg);
          }

          #custom-theme-color-input {
            flex: 1;
            min-width: 0;
          }

          .settings-preview-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
          }

          .settings-preview {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 10px;
            font-style: italic;
            color: var(--sj-text-muted);
          }

          #custom-theme-color-preview {
            width: 26px;
            height: 26px;
            border: 1px solid var(--sj-border-strong);
            border-radius: 7px;
            padding: 2px;
            background: var(--sj-input-bg);
          }

          .settings-mini-btn {
            padding: 4px 10px;
            border: 1px solid var(--sj-border-strong);
            border-radius: 7px;
            background-color: var(--sj-input-bg);
            color: var(--sj-text);
            font-family: var(--sj-font);
            font-size: 10px;
            font-weight: bold;
            cursor: pointer;
            transition: border-color 0.15s ease, color 0.15s ease, background-color 0.15s ease;
          }

          .settings-mini-btn:hover {
            border-color: var(--theme-hover-border);
            color: var(--theme-primary);
          }

          #uuid-spoofing-warning {
            max-height: 0;
            overflow: hidden;
            opacity: 0;
            margin: 0 0 0 0;
            padding: 0 8px;
            border-left: 3px solid rgba(255, 176, 0, 0.7);
            border-radius: 6px;
            background-color: rgba(255, 190, 0, 0.12);
            font-size: 10px;
            line-height: 1.35;
            color: var(--sj-text);
            transition: max-height 0.2s ease, opacity 0.2s ease, margin 0.2s ease, padding 0.2s ease;
          }

          #uuid-spoofing-warning.show {
            max-height: 100px;
            opacity: 1;
            margin: -2px 0 8px;
            padding: 6px 8px;
          }

          #uuid-regenerate-row {
            display: none;
            margin-top: -2px;
          }

          #uuid-spoofing-warning.show + #uuid-regenerate-row {
            display: flex;
          }

          .settings-mono {
            font-family: Consolas, 'Cascadia Code', monospace;
            font-size: 10.5px;
            color: var(--sj-text-muted);
            letter-spacing: 0.02em;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
          }

          .shortcuts-note {
            font-size: 10px;
            padding: 8px 10px;
            color: var(--sj-text);
            font-style: italic;
            margin-bottom: 10px;
            text-align: center;
            background-color: rgba(255, 190, 0, 0.12);
            border: 1px solid rgba(255, 176, 0, 0.25);
            border-radius: 8px;
            line-height: 1.35;
          }

          /* ------------------------------------------------------------
             Version / credit / fullscreen tray
             ------------------------------------------------------------ */
          #version {
            position: absolute;
            left: 54px;
            bottom: 14px;
            display: grid;
            grid-template-columns: 1fr 24px;
            align-items: center;
            gap: 4px;
            padding: 4px 8px;
            border-radius: 8px;
            cursor: pointer;
            transition: background-color 0.15s ease;
          }

          #version:hover {
            text-decoration: none;
            background-color: var(--theme-settings-hover);
          }

          #version:hover #version-link {
            color: var(--theme-primary);
          }

          /* version + credit sit on the always-dark page background, not on the card */
          #version-link {
            font-size: 12px;
            line-height: 20px;
            letter-spacing: 0.02em;
            color: rgba(255, 255, 255, 0.78);
            text-decoration: none;
            user-select: none;
            cursor: pointer;
            font-family: var(--sj-font);
            font-weight: bold;
            transition: color 0.15s ease;
          }

          #version-status-icon {
            background: url(images/core/core_form_input_status_icn_sprite.svg);
            background-repeat: no-repeat;
            background-size: 80px;
            width: 20px;
            height: 20px;
            opacity: 0.0;
          }

          #version-status-icon.check {
            background-position: -20px 0px;
            animation: spin 1500ms linear infinite;
            opacity: 1.0;
            transition-property: opacity;
            transition-duration: 0.5s;
          }

          #version-status-icon.download {
            opacity: 1.0;
          }

          #version-status-icon.restart {
            background-position: -40px 0px;
            opacity: 0.0;
            animation: fade 1.5s ease-out infinite;
          }

          #version-status-icon.error {
            background-position: -60px 0px;
            opacity: 0.0;
            animation: fade 1.5s ease-out infinite;
          }

          #button-tray {
            grid-area: button-tray;
            display: flex;
            flex-direction: row;
            justify-content: flex-end;
            gap: 6px;
            padding: 8px;
          }

          #button-tray ajd-button {
            width: 50px;
            height: 50px;
            border: 1px solid var(--theme-secondary);
            border-radius: 12px;
            background-color: var(--sj-surface);
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.3);
            transition: border-color 0.2s ease, transform 0.2s ease;
          }

          #button-tray ajd-button:hover {
            border-color: var(--theme-hover-border, #e83d52);
            transform: translateY(-1px);
          }

          #glockoma-credit {
            position: absolute;
            bottom: 14px;
            left: 50%;
            transform: translateX(-50%);
            font-family: var(--sj-font);
            font-size: 11px;
            color: rgba(255, 255, 255, 0.45);
            letter-spacing: 0.02em;
            white-space: nowrap;
          }

          #glockoma-credit a {
            color: var(--theme-primary);
            text-decoration: none;
            font-weight: bold;
          }

          #glockoma-credit a:hover {
            text-decoration: underline;
          }

          /* ------------------------------------------------------------
             Login help prompt
             ------------------------------------------------------------ */
          #login-help-prompt {
            display: none;
            position: fixed;
            bottom: 16px;
            left: 50%;
            transform: translateX(-50%) translateY(20px);
            background: var(--sj-surface);
            border: 1px solid var(--theme-secondary);
            border-radius: 16px;
            padding: 14px 20px;
            font-family: var(--sj-font);
            color: var(--sj-text);
            font-size: 14px;
            z-index: 100;
            box-shadow: var(--sj-shadow);
            opacity: 0;
            transition: opacity 0.3s ease, transform 0.3s ease;
            max-width: 420px;
            text-align: center;
            backdrop-filter: blur(14px);
          }

          #login-help-prompt.show {
            display: block;
            opacity: 1;
            transform: translateX(-50%) translateY(0);
          }

          #login-help-prompt p {
            margin: 0 0 12px 0;
            line-height: 1.4;
            font-family: var(--sj-display);
            font-size: 16px;
            color: var(--theme-primary, #e83d52);
            text-shadow: 1px 1px 0px var(--theme-shadow, rgba(252, 93, 93, 0.1));
          }

          .help-prompt-buttons {
            display: flex;
            gap: 8px;
            justify-content: center;
          }

          .help-prompt-btn {
            padding: 7px 18px;
            border-radius: 9px;
            border: 1px solid transparent;
            font-family: var(--sj-font);
            font-size: 12px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.2s ease;
          }

          .help-prompt-btn:active {
            transform: scale(0.96);
          }

          .help-prompt-btn-primary {
            background: var(--theme-button-bg, var(--theme-primary, #e83d52));
            border-color: var(--theme-button-border, var(--theme-secondary));
            color: var(--theme-button-text, white);
            box-shadow: 0 4px 12px var(--theme-shadow);
          }

          .help-prompt-btn-primary:hover {
            filter: brightness(1.08);
            transform: translateY(-1px);
          }

          .help-prompt-btn-dismiss {
            background: transparent;
            border-color: var(--sj-border-strong);
            color: var(--sj-text-muted);
          }

          .help-prompt-btn-dismiss:hover {
            border-color: var(--theme-hover-border, rgba(232, 61, 82, 0.5));
            color: var(--theme-primary, #e83d52);
          }

          /* ------------------------------------------------------------
             Floating tools (import accounts, wheel automation)
             ------------------------------------------------------------ */
          #auto-wheel-section {
            position: absolute;
            bottom: 10px;
            right: 10px;
            width: 300px;
            z-index: 1000;
            display: none;
          }

          #import-section {
            position: absolute;
            top: 10px;
            right: 10px;
            z-index: 1000;
            display: none;
          }

          #auto-wheel-section.visible {
            display: block;
          }

          #import-section.visible {
            display: block;
          }

          /* ------------------------------------------------------------
             Compact layout
             ------------------------------------------------------------ */
          @media (max-width: 950px), (max-height: 590px) {
            #box-background {
              display: none;
            }

            #panel,
            #account-panel-instance {
              display: none;
            }

            :host {
              display: flex;
              justify-content: center;
              align-items: center;
              overflow: auto;
              background-color: rgba(30, 27, 28, 0.14);
            }

            #box {
              padding: 30px 40px;
              max-width: 500px;
              width: 100%;
              background-color: var(--sj-surface);
              border-radius: var(--sj-radius-lg);
              border: 1px solid var(--theme-secondary);
              box-shadow: var(--sj-shadow);
            }

            :host(.dark-mode) #box {
              background-color: var(--theme-box-background-dark);
            }
          }

        </style>
        <div id="box-background"></div>
        <account-management-panel id="account-panel-instance" style="grid-area: panel; align-self: center;"></account-management-panel>
        <div id="button-tray" class="hidden">
          <ajd-button graphic="UI_fullScreen" id="expand-button">
          </ajd-button>
          <ajd-button graphic="UI_power" id="close-button">
          </ajd-button>
        </div>
        <div id="box">
          <div id="login-container">
            <img src="images/strawberry.png" alt="App Icon" id="login-app-icon" style="width:88px;display:block;margin-bottom:6px;margin-left:auto;margin-right:auto;" loading="lazy">
            <div id="player-login-text">playerLogin</div>
            <ajd-text-input id="username-input" placeholder="username" type="text"></ajd-text-input>
            <ajd-text-input id="password-input" placeholder="password" type="password"></ajd-text-input>
            <ajd-checkbox id="remember-me-cb" text="rememberMeText"></ajd-checkbox>
            <div id="login-btn-container">
              <ajd-bubble-button id="log-in-btn" text="login"></ajd-bubble-button>
              <img id="spinner" src="images/electron_login/log_spinner.svg" title="Cancel"></img>
            </div>
            <a id="forgot-password-link">forgotPassword</a>
            <div class="vertical-spacer"></div>
            <div id="need-account">needAccount?</div>
            <ajd-bubble-button id="create-account-btn" text="createAnimal"></ajd-bubble-button>
          </div>
        </div>
        <div id="glockoma-credit">
          Updated with ❤ by <a href="https://github.com/glvckoma" target="_blank" title="Original by glvckoma">Snipz</a>
        </div>

        <div class="button-container-bottom-left">
          <button id="settings-btn" title="Settings" class="icon-button"><svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/></svg></button>
          <div id="devtools-btn-wrapper">
            <button id="devtools-btn" title="View Debug Logs" class="icon-button"><svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/><polyline points="14 2 14 8 20 8"/><line x1="8" y1="13" x2="16" y2="13"/><line x1="8" y1="17" x2="16" y2="17"/></svg></button>
            <span id="devtools-error-badge">0</span>
          </div>
        </div>

        <div id="login-help-prompt">
          <p>Having trouble logging in?</p>
          <div class="help-prompt-buttons">
            <button id="help-prompt-view-logs" class="help-prompt-btn help-prompt-btn-primary">View Logs</button>
            <button id="help-prompt-dismiss" class="help-prompt-btn help-prompt-btn-dismiss">Dismiss</button>
          </div>
        </div>
        <div id="settings-panel">
          <h3>Settings</h3>
          <div class="settings-tabs">
            <button class="settings-tab active" data-tab="general">General</button>
            <button class="settings-tab" data-tab="theme">Theme</button>
            <button class="settings-tab" data-tab="shortcuts">Shortcuts</button>
          </div>

          <div class="settings-tab-content active" id="tab-general">
            <div class="settings-subsection">
              <h5>Enhancements</h5>
              <div class="settings-item settings-item-ingame" id="open-mod-menu-item">
                <span>Mod Menu</span>
                <button id="open-mod-menu-btn" class="settings-mini-btn" title="Open the in-game Mod Menu (F10)">Open · F10</button>
              </div>
              <div class="settings-item">
                <span>UUID Spoofing</span>
                <label style="display: inline-flex; align-items: center; cursor: pointer; position: relative;">
                  <input type="checkbox" id="uuid-spoofer-toggle" class="sr-only settings-peer">
                  <div class="settings-toggle"></div>
                </label>
              </div>
              <div id="uuid-spoofing-warning" class="hidden">
                Uses one fixed fake device ID, so 2FA only asks once per device. Generating a new ID makes 2FA ask again.
              </div>
              <div id="uuid-regenerate-row" class="settings-item">
                <span class="settings-mono" id="uuid-current-id" title="Current spoofed device ID">ID: …</span>
                <button id="uuid-regenerate-btn" class="settings-mini-btn" title="Generate a new random device ID">New ID</button>
              </div>
              <div class="settings-item" title="Unlocks GPU rendering, disables background throttling, and raises the client's process priority. Applies on the next client launch.">
                <span>High Performance Mode</span>
                <label style="display: inline-flex; align-items: center; cursor: pointer; position: relative;">
                  <input type="checkbox" id="high-performance-toggle" class="sr-only settings-peer">
                  <div class="settings-toggle"></div>
                </label>
              </div>
              <div class="settings-item">
                <span>Background Processing</span>
                <label style="display: inline-flex; align-items: center; cursor: pointer; position: relative;">
                  <input type="checkbox" id="background-processing-toggle" class="sr-only settings-peer">
                  <div class="settings-toggle"></div>
                </label>
              </div>
              <div class="settings-item">
                <span>Mod Menu Button</span>
                <label style="display: inline-flex; align-items: center; cursor: pointer; position: relative;">
                  <input type="checkbox" id="mod-menu-btn-toggle" class="sr-only settings-peer">
                  <div class="settings-toggle"></div>
                </label>
              </div>
              <div class="settings-item">
                <span>Server Swap</span>
                <select id="server-swap-select" class="settings-select">
                  <option value="">Default (US)</option>
                  <option value="en">English (US)</option>
                  <option value="fr">French</option>
                  <option value="de">German</option>
                  <option value="es">Spanish</option>
                  <option value="pt">Portuguese</option>
                </select>
              </div>
            </div>
            <div class="settings-subsection">
              <h5>Interface</h5>
              <div class="settings-item">
                <span>Dark Mode</span>
                <label style="display: inline-flex; align-items: center; cursor: pointer; position: relative;">
                  <input type="checkbox" id="dark-mode-toggle" class="sr-only settings-peer">
                  <div class="settings-toggle"></div>
                </label>
              </div>
              <div class="settings-item">
                <span>Import Accounts</span>
                <label style="display: inline-flex; align-items: center; cursor: pointer; position: relative;">
                  <input type="checkbox" id="show-import-accounts-toggle" class="sr-only settings-peer">
                  <div class="settings-toggle"></div>
                </label>
              </div>
              <div class="settings-item">
                <span>Wheel Automation</span>
                <label style="display: inline-flex; align-items: center; cursor: pointer; position: relative;">
                  <input type="checkbox" id="show-wheel-automation-toggle" class="sr-only settings-peer">
                  <div class="settings-toggle"></div>
                </label>
              </div>
              <div class="settings-item">
                <span>Hide DevTools Badge</span>
                <label style="display: inline-flex; align-items: center; cursor: pointer; position: relative;">
                  <input type="checkbox" id="hide-devtools-badge-toggle" class="sr-only settings-peer">
                  <div class="settings-toggle"></div>
                </label>
              </div>
            </div>
          </div>

          <div class="settings-tab-content" id="tab-theme">
            <div class="settings-item" id="custom-theme-color-item">
              <span>Custom Theme</span>
              <label style="display: inline-flex; align-items: center; cursor: pointer; position: relative;">
                <input type="checkbox" id="custom-theme-enabled-toggle" class="sr-only settings-peer">
                <div class="settings-toggle"></div>
              </label>
            </div>
            <div id="custom-theme-color-container">
              <div class="settings-field">
                <label class="settings-field-label">Custom Name</label>
                <input type="text" id="custom-theme-name-input" class="settings-input settings-input-full" placeholder="Custom Jam" maxlength="50">
              </div>
              <div class="settings-field">
                <label class="settings-field-label">Fruit Icon</label>
                <select id="custom-theme-fruit-select" class="settings-select settings-input-full">
                  <option value="strawberry.png">Strawberry</option>
                  <option value="banana.png">Banana</option>
                  <option value="blueberry.png">Blueberry</option>
                  <option value="cantaloupe.png">Cantaloupe</option>
                  <option value="coconut.png">Coconut</option>
                  <option value="dragonfruit.png">Dragonfruit</option>
                  <option value="pineapple.png">Pineapple</option>
                  <option value="pumpkin.png">Pumpkin</option>
                </select>
              </div>
              <div class="settings-color-row">
                <input type="color" id="custom-theme-color-picker" value="#e83d52">
                <input type="text" id="custom-theme-color-input" class="settings-input" placeholder="#e83d52" maxlength="7">
              </div>
              <div class="settings-preview-row">
                <div class="settings-preview">
                  <img id="custom-theme-color-preview" src="images/strawberry.png" alt="Preview">
                  <span>Preview</span>
                </div>
                <button id="reset-custom-theme-color-btn" class="settings-mini-btn">Reset</button>
              </div>
            </div>
          </div>

          <div class="settings-tab-content" id="tab-shortcuts">
            <div class="shortcuts-note">Note: Click on the left or right side panels first to focus the window before using shortcuts</div>
            <div class="settings-subsection">
              <h5>General</h5>
              <div class="settings-shortcut"><kbd>Ctrl + Shift + I</kbd>Toggle Developer Tools</div>
              <div class="settings-shortcut"><kbd>Ctrl + R</kbd>Reload / Logout (Return to Login Screen)</div>
              <div class="settings-shortcut"><kbd>Ctrl + Shift + H</kbd>Toggle Hide UI Elements (Settings/Report Buttons &amp; User Tray)</div>
            </div>
            <div class="settings-subsection">
              <h5>In-Game</h5>
              <div class="settings-shortcut"><kbd>F5</kbd>Toggle In-Game HUD</div>
              <div class="settings-shortcut"><kbd>F9</kbd>Prepare for Screenshot</div>
              <div class="settings-shortcut"><kbd>F10</kbd>Toggle Mod Menu</div>
            </div>
            <div class="settings-subsection">
              <h5>Windows/Linux</h5>
              <div class="settings-shortcut"><kbd>Alt + Enter / F11</kbd>Toggle Fullscreen</div>
              <div class="settings-shortcut"><kbd>Ctrl + Q / Alt + F4</kbd>Quit Application</div>
            </div>
          </div>
        </div>

        <div id="version">
          <a id="version-link">0.0.0</a>
          <ajd-progress-ring id="version-status-icon" stroke-color="#64cc4d" stroke-width="3" radius="11"></ajd-progress-ring>
        </div>

        <!-- Import Button Section -->
        <div id="import-section">
          <import-button id="import-button-instance"></import-button>
        </div>

        <!-- Auto Wheel Section -->
        <div id="auto-wheel-section">
          <auto-wheel-button id="auto-wheel-button-instance"></auto-wheel-button>
        </div>

  `;
  window.LoginScreenTemplate = () => TEMPLATE;
})();
