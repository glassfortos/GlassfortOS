// SPDX-License-Identifier: GPL-3.0-or-later
// Glassfort website: tower tilt, rollback demo, light/dark switch, release info.
"use strict";

const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

// The tower turns slightly towards the pointer, as if light moved across glass.
const tower = document.querySelector(".tower");
if (tower && !reduced) {
  window.addEventListener("pointermove", (e) => {
    const x = (e.clientX / window.innerWidth) * 2 - 1;
    const y = (e.clientY / window.innerHeight) * 2 - 1;
    tower.style.setProperty("--mx", x.toFixed(3));
    tower.style.setProperty("--my", y.toFixed(3));
  }, { passive: true });
}

// Rollback demo: ok -> breaking -> broken -> (pick snapshot) -> restoring -> restored.
const demo = document.querySelector(".demo");
if (demo) {
  const msg = demo.querySelector(".demo-msg");
  const breakBtn = demo.querySelector('[data-act="break"]');
  const resetBtn = demo.querySelector('[data-act="reset"]');
  const snaps = demo.querySelectorAll("[data-snap]");
  const wait = (ms) => new Promise((r) => setTimeout(r, reduced ? 0 : ms));
  const set = (state, text) => { demo.dataset.state = state; msg.textContent = text; };

  breakBtn.addEventListener("click", async () => {
    breakBtn.disabled = true;
    set("breaking", "Updating… a package the system needs to start is being removed.");
    await wait(1100);
    set("broken", "The computer no longer starts. In the boot menu, pick the snapshot from before the update.");
    snaps.forEach((b) => { b.disabled = false; });
    demo.querySelector('[data-snap="good"]').focus({ preventScroll: true });
  });

  snaps.forEach((b) => b.addEventListener("click", async () => {
    if (b.dataset.snap === "bad") {
      msg.textContent = "That snapshot was taken after the update, so it is broken too. Pick the one from before.";
      return;
    }
    snaps.forEach((s) => { s.disabled = true; });
    b.classList.add("picked");
    set("restoring", "Booting the snapshot and making it the system again…");
    await wait(1400);
    set("restored", "Back to normal. Your files in your home folder were never touched.");
    breakBtn.hidden = true;
    resetBtn.hidden = false;
    resetBtn.focus({ preventScroll: true });
  }));

  resetBtn.addEventListener("click", () => {
    snaps.forEach((s) => { s.disabled = true; s.classList.remove("picked"); });
    set("ok", "Your system is fine. Install an update that goes wrong.");
    resetBtn.hidden = true;
    breakBtn.hidden = false;
    breakBtn.disabled = false;
    breakBtn.focus({ preventScroll: true });
  });
}

// Light/dark screenshot: the light version wipes in like a pane sliding over.
const stack = document.querySelector(".shot-stack");
document.querySelectorAll(".mode-switch button").forEach((btn, _i, all) => {
  btn.addEventListener("click", () => {
    stack.dataset.mode = btn.dataset.mode;
    all.forEach((b) => b.setAttribute("aria-pressed", String(b === btn)));
  });
});

// Download: release.json holds the published ISO; without a URL the page
// keeps the "not released yet" text.
(async () => {
  let rel;
  try {
    const res = await fetch("release.json", { cache: "no-cache" });
    if (!res.ok) return;
    rel = await res.json();
  } catch {
    return;
  }
  if (!rel || !rel.url) return;
  const ready = document.querySelector('[data-dl="ready"]');
  const field = (name) => ready.querySelector(`[data-field="${name}"]`);
  field("version").textContent = rel.version;
  field("date").textContent = new Date(rel.date).toLocaleDateString("en", { year: "numeric", month: "long", day: "numeric" });
  field("url").href = rel.url;
  field("size").textContent = rel.size;
  field("sha256").textContent = rel.sha256;
  if (rel.signature) field("signature").href = rel.signature;
  else ready.querySelector('[data-optional="signature"]').hidden = true;
  document.querySelector('[data-dl="pending"]').hidden = true;
  ready.hidden = false;
})();
