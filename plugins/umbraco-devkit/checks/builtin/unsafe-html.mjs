// Lit's unsafeHTML or unsafeSVG added in a file that never calls sanitizeHTML. Anything rendered
// that way runs as markup, so it needs sanitizing unless it's a constant the package controls.

const SCRIPT = /\.(ts|tsx|js|mjs)$/i;
const UNSAFE = /\bunsafe(HTML|SVG)\s*\(/;

export default {
  name: "unsafe-html",
  files: (path) => SCRIPT.test(path),
  checkFile({ added, text }) {
    if (text === null || /\bsanitizeHTML\s*\(/.test(text)) return [];
    return added
      .filter((l) => UNSAFE.test(l.text))
      .map((l) => ({ line: l.line, message: "unsafeHTML/unsafeSVG with no sanitizeHTML in this file; sanitize it, or say why it's safe" }));
  },
};
