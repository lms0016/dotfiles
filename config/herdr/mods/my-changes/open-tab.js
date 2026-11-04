// Opens a center tab for a viewer mod, or returns to the one already open for this key.
// Mods cannot import across folders, so my-files and my-changes each carry this file.
//
// Tabs are matched by name because spaces() does not show a new tab until the next
// render, so the id of a tab created here is not available to record.
import { spaces, shared, setShared, run } from "herdr";

const STATE = "viewer.tabs";

export function openTab(key, { space, name, ...options }) {
  const tabs = spaces().find((s) => s.id === space)?.tabs ?? [];
  const known = shared(STATE) ?? {};
  const slot = (tabName) => `${space}/${tabName}`;

  const existing = tabs.find((tab) => tab.named && known[slot(tab.name)] === key);
  if (existing) {
    run("tab.select", { id: existing.id });
    return;
  }

  // Two files with the same name in one space get "name", then "name (2)".
  const taken = new Set(tabs.map((tab) => tab.name));
  let label = name;
  for (let n = 2; taken.has(label); n++) label = `${name} (${n})`;

  // Entries for closed tabs are dropped here so the shared state cannot grow forever.
  const open = Object.fromEntries(Object.entries(known).filter(([entry]) =>
    !entry.startsWith(`${space}/`) || tabs.some((tab) => slot(tab.name) === entry)));
  open[slot(label)] = key;
  setShared(STATE, open);
  run("tab.new", { space, name: label, ...options });
}
