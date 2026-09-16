"use strict";
(() => {
  customElements.define("ajd-forgot-password-modal", class extends HTMLElement {
    constructor() {
      super();

      this.attachShadow({mode: "open"}).innerHTML = `
        <style>
          :host {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            width: 100vw;
          }


          #modal-body {
            display: flex;
            flex-direction: column;
            width: 600px;
            border-radius: 20px;
            background-color: rgba(26, 26, 30, 0.97);
            border: 1px solid rgba(255, 255, 255, 0.12);
            box-shadow: 0 24px 60px rgba(0, 0, 0, 0.55), 0 0 0 1px var(--theme-secondary, rgba(232, 61, 82, 0.3));
            backdrop-filter: blur(14px);
            overflow: hidden;
            font-family: CCDigitalDelivery, sans-serif;
            color: #ECECEE;
            font-size: 16px;
            text-align: center;
          }

          #header-div {
            font-family: Tiki-Island, sans-serif;
            font-size: 30px;
            position: relative;
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            padding: 14px 10px 12px;
            color: var(--theme-primary, #e83d52);
            text-shadow: 1px 2px 0px rgba(0, 0, 0, 0.35);
            letter-spacing: 0.5px;
          }

          #body-div {
            border-bottom: 1px solid rgba(255, 255, 255, 0.08);
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
          }

          #body-text {
            margin: 10px 10px 24px 10px;
          }

          #body-div ajd-text-input {
            width: 300px;
            --sj-input-bg: rgba(255, 255, 255, 0.06);
            --sj-input-text: #F3F3F5;
            --sj-input-placeholder: rgba(255, 255, 255, 0.38);
            --sj-text-muted: #A6A6AE;
            --ajd-input-radius: 14px;
            background-color: rgba(255, 255, 255, 0.06);
            border: 1.5px solid rgba(255, 255, 255, 0.12);
            border-radius: 14px;
            margin-bottom: 8px;
          }

          #submit-div {
            display: flex;
            justify-content: center;
            align-items: center;
            padding-top: 18px;
            padding-bottom: 28px;
          }

          #close-button {
            position: absolute;
            z-index: 1;
            right: 10px;
            top: 10px;
            width: 30px;
            height: 30px;
            border: none;
            background-color: transparent;
            color: #B0B0B8;
            font-size: 24px;
            font-weight: bold;
            cursor: pointer;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 4px;
            transition: background-color 0.2s;
          }

          #close-button:hover {
            background-color: rgba(255, 255, 255, 0.08);
            color: #FFFFFF;
          }

          #close-button:active {
            background-color: rgba(255, 255, 255, 0.14);
          }

          ajd-bubble-button {
            --ajd-bubble-button-background-color: var(--theme-button-bg, var(--theme-primary, #e83d52));
            --ajd-bubble-button-border-color: var(--theme-button-border, rgba(0, 0, 0, 0.25));
            --ajd-bubble-button-text-color: var(--theme-button-text, #FFFFFF);
            font-size: 24px;
          }
          #body-text {
            color: #C9C9D0;
            line-height: 1.45;
          }
        </style>

        <div id="modal-body">
          <div id="header-div">
            <span id="header-text">reset password</span>
            <button id="close-button" type="button">×</button>
          </div>
          <div id="body-div">
            <span id="body-text">
              Change yer name, yo!
            </span>
            <ajd-text-input id="username-input" placeholder="username" type="text"> </ajd-text-input>
            <ajd-text-input id="email-input" placeholder="parent email" type="text"> </ajd-text-input>
          </div>
          <div id="submit-div">
            <ajd-bubble-button id="submit-button" text="submit" disabled="true"></ajd-bubble-button>
          </div>
        </div>
      `;

      this.headerDivElem = this.shadowRoot.getElementById("header-text");

      this.bodyTextElem = this.shadowRoot.getElementById("body-text");

      this.emailInputElem = this.shadowRoot.getElementById("email-input");
      this.emailInputElem.addEventListener("keyup", event => {
        this.submitButtonElem.disabled = !this.usernameInputElem.value || !this.emailInputElem.value;
      });

      this.usernameInputElem = this.shadowRoot.getElementById("username-input");
      this.usernameInputElem.addEventListener("keyup", event => {
        this.submitButtonElem.disabled = !this.usernameInputElem.value || !this.emailInputElem.value;
      });

      this.submitButtonElem = this.shadowRoot.getElementById("submit-button");
      this.submitButtonElem.addEventListener("click", async event => {
        if (this.usernameInputElem.value && this.emailInputElem.value) {
          try {
            const body = `username=${encodeURIComponent(this.usernameInputElem.value)}&parent_email=${encodeURIComponent(this.emailInputElem.value)}`;

            const response = await globals.fetch(`${globals.config.web}/child_request_reset_password`, {
              method: "POST",
              mode: "cors",
              headers: {
                "Content-Type": "application/x-www-form-urlencoded"
              },
              body,
            }, [422]);

            if (response.status === 422) {
              const {message} = JSON.parse(await response.text());
              if (message === "I'm sorry, we cannot find an account matching that username.") {
                this.usernameInputElem.error = await globals.translate("userNotFound");
              }
              else if (message === "The email address you entered does not match our records") {
                this.emailInputElem.error = await globals.translate("wrongEmail");
              }
              else if (message === "You must enter both a username and an email address") {
                this.usernameInputElem.error = await globals.translate("usernameEmailRequired");
              }
              else {
                globals.genericError(message);
              }
            }
            else if (response.status === 200) {
              const {message} = JSON.parse(await response.text());
              const modal = document.createElement("ajd-message-modal");
              modal.header = await globals.translate("success");
              modal.body = message;
              modal.buttonText = await globals.translate("ok");              modal.addEventListener("close", event => {
                document.getElementById("modal-layer").removeChild(modal);
              });
              document.getElementById("modal-layer").appendChild(modal);
              this.dispatchEvent(new CustomEvent("close"));
            }
            else {
              globals.genericError("UNHANDLED_PASSWORD_RESET_ERROR");
            }
          }
          catch (err) {
            globals.genericError(err);
          }
        }
      });


      this.closeButtonElem = this.shadowRoot.getElementById("close-button");
      this.closeButtonElem.addEventListener("click", async event => {
        this.dispatchEvent(new CustomEvent("close"));
      });
    }

    connectedCallback() {
      syncModalTheme(this);
      this.localize();
    }

    async localize() {
      this.headerDivElem.innerText = await globals.translate("passwordReset");
      this.bodyTextElem.innerText = await globals.translate("forgotPasswordNote");
      this.submitButtonElem.text = await globals.translate("submit");
      this.usernameInputElem.placeholder = await globals.translate("username");
      this.emailInputElem.placeholder = await globals.translate("parentEmail");
    }
  });
})(); 