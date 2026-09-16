"use strict";

(() => {
  customElements.define("ajd-message-modal", class extends HTMLElement {
    constructor() {
      super();

      this._userData = null;

      this.attachShadow({mode: "open"}).innerHTML = `
        <style>
          :host {
            display: flex;
            z-index: 10;
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
            padding: 20px;
          }

          #submit-div {
            display: flex;
            justify-content: center;
            align-items: center;
            padding-bottom: 18px;
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
            <span id="header-text">Yay!</span>
          </div>
          <div id="body-div">
            <span id="body-text">
              Yer name changed, yo!
            </span>
          </div>
          <div id="submit-div">
            <ajd-bubble-button id="ok-button" text="OK!"></ajd-bubble-button>
          </div>
        </div>
      `;

      this.headerTextElem = this.shadowRoot.getElementById("header-text");

      this.bodyTextElem = this.shadowRoot.getElementById("body-text");

      this.okButtonElem = this.shadowRoot.getElementById("ok-button");
      this.okButtonElem.addEventListener("click", async event => {
        this.dispatchEvent(new CustomEvent("close"));
      });
    }

    connectedCallback() {
      syncModalTheme(this);
    }

    set header (text) {
      this._header = text;
      this.headerTextElem.innerText = text;
    }

    get header () {
      return this._header;
    }

    set body (text) {
      this._body = text;
      this.bodyTextElem.innerText = text;
    }

    get body () {
      return this._body;
    }

    set buttonText (text) {
      this._buttonText = text;
      this.okButtonElem.text = text;
    }

    get buttonText () {
      return this._buttonText;
    }

  });
})();
