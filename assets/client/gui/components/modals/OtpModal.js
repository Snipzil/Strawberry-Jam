"use strict";
(() => {
  customElements.define("otp-modal", class extends HTMLElement {
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
            <span id="header-text">2-STEP VERIFICATION</span>
            <button id="close-button" type="button">×</button>
          </div>
          <div id="body-div">
            <span id="body-text">
              Enter the Verification Code sent to your parent's email:
            </span>
            <ajd-text-input id="otp-input" placeholder="Code" type="text"> </ajd-text-input>
          </div>
          <div id="submit-div">
            <ajd-bubble-button id="submit-button" text="Verify" disabled="true"></ajd-bubble-button>
          </div>
        </div>
      `;

      this.headerDivElem = this.shadowRoot.getElementById("header-text");

      this.bodyTextElem = this.shadowRoot.getElementById("body-text");

      this.otpInputElem = this.shadowRoot.getElementById("otp-input");
      this.otpInputElem.addEventListener("keyup", event => {
        this.submitButtonElem.disabled = !this.otpInputElem.value;
      });

      this.submitButtonElem = this.shadowRoot.getElementById("submit-button");
      this.submitButtonElem.addEventListener("click", async event => {
        if (this.otpInputElem.value) {
          this.dispatchEvent(new CustomEvent("submit", {detail:{otp: this.otpInputElem.value}}));
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
      this.headerDivElem.innerText = await globals.translate("otpTitle");
      this.bodyTextElem.innerText = await globals.translate("otpMessage");
      this.submitButtonElem.text = await globals.translate("otpButton");
      this.otpInputElem.placeholder = await globals.translate("otpLabel");
    }
  });
})();
