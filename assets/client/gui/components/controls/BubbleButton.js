"use strict";

(() => {
  customElements.define("ajd-bubble-button", class extends HTMLElement {
    static get observedAttributes() {
      return ["text", "disabled"];
    }

    constructor() {
      super();

      this._text = "";
      this._disabled = false;

      this.attachShadow({mode: "open"}).innerHTML = `
      <style>
      :host {
        position: relative;
        display: inline-block;
        background-color: var(--ajd-bubble-button-background-color, #d0004a);
        border: 1px solid var(--ajd-bubble-button-border-color, #272727);
        color: var(--ajd-bubble-button-text-color, #FFFFFF);
        user-select: none;
        font-family: 'Tiki-Island', 'CCDigitalDelivery', sans-serif;
        font-size: 27px;
        line-height: 1.15;
        letter-spacing: 0.4px;
        border-radius: 12px;
        padding: 8px 28px;
        white-space: nowrap;
        box-sizing: border-box;
        box-shadow:
          inset 0 1px 0 rgba(255, 255, 255, 0.22),
          0 6px 16px rgba(0, 0, 0, 0.22);
        text-shadow: 0 1px 0 rgba(0, 0, 0, 0.18);
        transition: transform 0.18s cubic-bezier(0.34, 1.56, 0.64, 1), box-shadow 0.18s ease, filter 0.18s ease, background-color 0.25s ease, border-color 0.25s ease, color 0.25s ease;
        overflow: hidden;
      }

      :host::after {
        content: '';
        position: absolute;
        inset: 0;
        pointer-events: none;
        background: linear-gradient(180deg, rgba(255, 255, 255, 0.14) 0%, rgba(255, 255, 255, 0) 55%);
        border-radius: inherit;
      }

      :host(:hover) {
        background-color: var(--ajd-bubble-button-background-color-hover, var(--ajd-bubble-button-background-color, #d0004a));
        border-color: var(--ajd-bubble-button-border-color-hover, var(--ajd-bubble-button-border-color, #272727));
        cursor: pointer;
        filter: brightness(1.06);
        transform: translateY(-1px);
        box-shadow:
          inset 0 1px 0 rgba(255, 255, 255, 0.25),
          0 10px 22px rgba(0, 0, 0, 0.26);
      }

      :host(:active) {
        background-color: var(--ajd-bubble-button-background-color-active, var(--ajd-bubble-button-background-color, #d0004a));
        border-color: var(--ajd-bubble-button-border-color-active, var(--ajd-bubble-button-border-color, #272727));
        filter: brightness(0.96);
        transform: translateY(1px) scale(0.985);
        box-shadow:
          inset 0 2px 4px rgba(0, 0, 0, 0.18),
          0 3px 8px rgba(0, 0, 0, 0.2);
      }

      :host([disabled]) {
        color: rgba(255, 255, 255, 0.7);
        background-color: #8f8f96;
        border-color: rgba(0, 0, 0, 0.15);
        box-shadow: 0 3px 8px rgba(0, 0, 0, 0.18);
        filter: none;
        transform: none;
        cursor: default;
      }

      :host([disabled])::after {
        opacity: 0.4;
      }
    </style>
    <div id="button"></div>
      `;

      this.buttonElem = this.shadowRoot.getElementById("button");
    }

    attributeChangedCallback(name, oldVal, newVal) {
      switch (name) {
        case "text": this.text = newVal; break;
        case "disabled": this.disabled = newVal; break;
      }
    }

    get text() {
      return this.getAttribute("text");
    }

    set text(val) {
      if (val === this._text) {
        return;
      }

      this._text = val;
      this.setAttribute("text", this._text);
      this.buttonElem.textContent = this._text;
    }

    get disabled() {
      return this._disabled;
    }

    set disabled(val) {
      if (this._disabled && val === "" || globals.parseBool(val) === this._disabled) {
        return;
      }

      this._disabled = globals.parseBool(val);
      if (this._disabled) {
        this.setAttribute("disabled", "");
      }
      else {
        this.removeAttribute("disabled");
      }
    }
  });
})();
