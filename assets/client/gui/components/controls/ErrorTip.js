"use strict";

(() => {
  customElements.define("ajd-error-tip", class extends HTMLElement {
    static get observedAttributes() {
      return ["text"];
    }

    constructor() {
      super();

      this._text = "";

      this.attachShadow({mode: "open"}).innerHTML = `
        <style>
          :host {
            display: flex;
            align-items: center
          }

          #text {
            padding: 10px 14px;
            font-family: CCDigitalDelivery, 'Segoe UI', sans-serif;
            font-size: 12.5px;
            color: #FFFFFF;
            background-color: #2a2a2f;
            border: var(--theme-primary, #FF4A26) 1px solid;
            border-radius: 12px;
            letter-spacing: .4px;
            text-align: center;
            line-height: 17px;
            text-shadow: 0 1px 0 rgba(0, 0, 0, 0.3);
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.35), 0 0 0 3px var(--theme-shadow, rgba(252, 93, 93, 0.1));
          }

          #tip {
            border-top: 9px solid transparent;
            border-bottom: 9px solid transparent;
            border-left: 12px solid #2a2a2f;
          }
        </style>
        <div id="text"></div>
        <div id="tip"></div>
      `;

      this.textElem = this.shadowRoot.getElementById("text");
    }

    attributeChangedCallback(name, oldVal, newVal) {
      if (newVal === oldVal) {
        return;
      }

      switch (name) {
        case "text": this.text = newVal; break;
      }
    }

    get text() {
      return this._text;
    }

    set text(val) {
      this._text = val;
      this.setAttribute("text", this._text);
      this.textElem.textContent = this._text;
    }
  });
})();
