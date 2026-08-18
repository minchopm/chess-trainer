// Small DOM helpers shared by the modes.

export function el(tag, props = {}, children = []) {
  const node = document.createElement(tag);
  for (const [key, value] of Object.entries(props)) {
    if (key === 'class') node.className = value;
    else if (key === 'html') node.innerHTML = value;
    else if (key === 'text') node.textContent = value;
    else if (key.startsWith('on') && typeof value === 'function') {
      node.addEventListener(key.slice(2).toLowerCase(), value);
    } else if (value === true) node.setAttribute(key, '');
    else if (value !== false && value != null) node.setAttribute(key, value);
  }
  for (const child of [children].flat()) {
    if (child == null || child === false) continue;
    node.append(typeof child === 'string' ? document.createTextNode(child) : child);
  }
  return node;
}

export function card(title, children) {
  return el('section', { class: 'card' }, [
    title ? el('h3', { class: 'panel-title', text: title }) : null,
    ...[children].flat(),
  ]);
}

export function button(label, onClick, { primary = false, disabled = false } = {}) {
  return el('button', {
    class: `btn${primary ? ' primary' : ''}`,
    onClick,
    disabled,
  }, [label]);
}

export function stat(label, value, hint) {
  return el('div', { class: 'stat' }, [
    el('div', { class: 'value', text: String(value) }),
    el('div', { class: 'label', text: label }),
    hint ? el('div', { class: 'subtle', text: hint }) : null,
  ]);
}

export function feedback(verdict, heading, body) {
  return el('div', { class: 'feedback', 'data-verdict': verdict }, [
    el('h4', { text: heading }),
    ...[body].flat().map((line) => (typeof line === 'string' ? el('p', { html: line }) : line)),
  ]);
}

export function tags(list) {
  return el('div', { class: 'tag-row' }, list.map((name) => el('span', { class: 'tag', text: humanise(name) })));
}

/** camelCase / mateIn2 -> "Mate in 2", "Knight fork". */
export function humanise(name) {
  const spaced = name
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/([a-zA-Z])(\d)/g, '$1 $2')
    .toLowerCase();
  return spaced.charAt(0).toUpperCase() + spaced.slice(1);
}

export function clear(node) {
  node.replaceChildren();
  return node;
}

/**
 * Replace a node's contents, dropping null/false children. Element.append()
 * stringifies null into the literal text "null", which is exactly the kind of
 * thing that leaks into a UI built out of conditional sections.
 */
export function fill(node, ...children) {
  node.replaceChildren();
  return append(node, ...children);
}

/** Append children to a node, dropping null/false entries. */
export function append(node, ...children) {
  for (const child of children.flat(Infinity)) {
    if (child == null || child === false) continue;
    node.append(child);
  }
  return node;
}
