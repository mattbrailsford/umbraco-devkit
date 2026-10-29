# Recording a GIF of an interaction

A GIF shows a reviewer what a still screenshot can't: a drag and drop, an animation, a
screen that changes live, a short flow across several screens. It sits beside the
screenshot in the PR, never in place of it.

## The limits

| Rule | Value | Why |
|---|---|---|
| Viewport | 1440×900, same as screenshots | The GIF and the still line up |
| Crop | Everything the action shows, plus the screenshot's 24px margin; whole pixels | A popover that opens mid-action isn't cut off; a fractional crop comes out a pixel short |
| Scale | Never shrink | Half size makes backoffice text unreadable |
| Frame rate | About 10 frames a second | Smooth enough; faster only makes the file bigger |
| Length | One action, 10 seconds or less | A reviewer watches one thing at a time |
| Last frame | Held for 2 seconds | The result stays on screen long enough to read |
| File size | Under 5 MB | Keeps the plan folder and the PR page light |
| Pointer | A visible dot that follows the mouse | Screenshots leave out the real cursor |

Over 5 MB or 10 seconds: crop tighter or split the action in two. Don't shrink the image or
drop the frame rate below 10.

## How to record

Screenshots taken one at a time through browser tools are far too slow for 10 frames a
second, so record with a short Playwright script. Run it from a scratch folder outside the
repo, so its packages never reach the project:

```bash
npm i playwright@1.64.1 gifenc@1.0.3 pngjs@7.0.0 && npx playwright install chromium
```

If the project's e2e suite already has Playwright, use its version instead. No `ffmpeg` is
needed; the copy Playwright ships with can't write GIFs.

Save this as `record-gif.mjs` in the scratch folder:

```js
import gifenc from 'gifenc'; const { GIFEncoder, quantize, applyPalette } = gifenc;
import { PNG } from 'pngjs'; import fs from 'fs';

const FPS = 10, HOLD_MS = 2000, MARGIN = 24;

// Screenshots leave out the real cursor, so draw a dot. During a native drag the browser
// stops sending mousemove, so dragover and drag move the dot too.
export const pointerScript = `(() => {
  const add = () => { const d = document.createElement('div');
    d.style.cssText = 'position:fixed;left:-50px;top:-50px;width:14px;height:14px;margin:-7px 0 0 -7px;border-radius:50%;background:#ff00ff;border:2px solid #fff;box-shadow:0 0 0 1px #0006;pointer-events:none;z-index:2147483647';
    document.documentElement.appendChild(d);
    const move = e => { if (e.clientX || e.clientY) { d.style.left = e.clientX + 'px'; d.style.top = e.clientY + 'px'; } };
    for (const t of ['mousemove', 'mousedown', 'dragover', 'drag']) addEventListener(t, move, true); };
  document.readyState === 'loading' ? addEventListener('DOMContentLoaded', add) : add(); })()`;

// Records `action` into <name>.gif and saves the end state as <name>.png. `area` lists
// selectors for everything the action shows: the changed part, and any popover, dropdown or
// dialog it opens. Frames are taken whole and cropped afterwards to every place those
// elements reached, plus the margin, so nothing that appears mid-action is cut off.
export async function record(page, { name, area, action }) {
  const frames = []; let on = true; const t0 = Date.now();
  let box = null;
  const grow = async () => { for (const sel of area) for (const el of await page.locator(sel).all()) {
    const b = await el.boundingBox().catch(() => null); if (!b || !b.width || !b.height) continue;
    box = box ? { x1: Math.min(box.x1, b.x), y1: Math.min(box.y1, b.y),
                  x2: Math.max(box.x2, b.x + b.width), y2: Math.max(box.y2, b.y + b.height) }
              : { x1: b.x, y1: b.y, x2: b.x + b.width, y2: b.y + b.height }; } };
  const loop = (async () => { while (on) {
    const s = Date.now(); frames.push({ t: s - t0, buf: await page.screenshot() }); await grow();
    const wait = 1000 / FPS - (Date.now() - s); if (wait > 0) await page.waitForTimeout(wait); } })();
  await action(); on = false; await loop; await grow();
  if (!box) throw new Error('None of the area selectors were visible during the recording');
  const vp = page.viewportSize();
  const x = Math.max(0, Math.floor(box.x1 - MARGIN)), y = Math.max(0, Math.floor(box.y1 - MARGIN));
  const w = Math.min(vp.width, Math.ceil(box.x2 + MARGIN)) - x, h = Math.min(vp.height, Math.ceil(box.y2 + MARGIN)) - y;
  const crop = buf => { const src = PNG.sync.read(buf), out = new PNG({ width: w, height: h });
    PNG.bitblt(src, out, x, y, w, h, 0, 0); return out; };
  fs.writeFileSync(`${name}.png`, PNG.sync.write(crop(frames.at(-1).buf)));
  const gif = GIFEncoder();
  frames.forEach((f, i) => { const png = crop(f.buf); const palette = quantize(png.data, 256);
    const delay = i < frames.length - 1 ? frames[i + 1].t - f.t : HOLD_MS;
    gif.writeFrame(applyPalette(png.data, palette), w, h, { palette, delay }); });
  gif.finish(); fs.writeFileSync(`${name}.gif`, gif.bytes());
  return { frames: frames.length, ms: frames.at(-1).t, bytes: fs.statSync(`${name}.gif`).size, crop: { x, y, width: w, height: h } };
}
```

Then a script for the action itself:

```js
import { chromium } from 'playwright';
import { record, pointerScript } from './record-gif.mjs';

const browser = await chromium.launch();
const context = await browser.newContext({ viewport: { width: 1440, height: 900 },
  storageState: 'auth.json' });              // the logged-in session; see below
await context.addInitScript(pointerScript);  // before the first page loads
const page = await context.newPage();
await page.goto('https://localhost:<port>/umbraco/section/...');

// The changed part, plus every popover, dropdown or dialog the action opens.
const area = ['<the changed area>', '<a popover the action opens>'];
console.log(await record(page, { name: '<screen>-<action>', area, action: async () => {
  await page.waitForTimeout(500);            // a still moment before the action starts
  // Move with page.mouse in small steps with short waits, so the dot travels visibly.
  // A single click or dragTo jumps straight there and the viewer can't follow it.
  await page.waitForTimeout(800);            // let the result settle before the hold
}}));
await browser.close();
```

**Logging in.** Log in to the backoffice once in the same script (or the e2e suite's setup)
and save the session with `context.storageState({ path: 'auth.json' })`. Keep `auth.json`
in the scratch folder: it holds a live login and never goes in the repo.

## Check before saving

- The printed `ms` is 10,000 or less, and `bytes` is under 5 MB.
- Open the last frame: nothing the action opened touches the image edge. If it does, its
  selector is missing from `area`.
- Open a frame from the middle of the action: the dot is there and on the right element.
- The last frame shows the result, not a half-finished state.

Copy `<screen>-<action>.gif` into the plan folder's `screenshots/`. The `.png` the script
saved is the end state; use it as `<screen>.png` only if that screenshot doesn't exist yet.
