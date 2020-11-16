class Stack extends HTMLElement {
  constructor(showTabs = false) {
    super();
    this.attachShadow({mode: 'open'});

    const wrapper = document.createElement('div');
    wrapper.setAttribute('class','wrapper');

    const style = document.createElement('style');
    style.textContent = `.wrapper {
      display: grid;
      grid-template-columns: 1fr;
      grid-template-rows: 1fr
    }`

    this.shadowRoot.append(style, wrapper);

    if (showTabs) {
      // add a tabs bar to the parent;
    }
  }

  add(title, element) {
    element.style["grid-area"] = "1 / 1";
  }

  remove(title) {}
}

window.customElements.define("widget-stack", Stack);

module.exports = { Stack }