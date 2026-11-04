// Gives a viewer the keyboard whenever its pane becomes the focused one, so its
// `mod:<name>` keys work without a click first.
// Mods cannot import across folders, so file-viewer and diff-viewer each carry this file.
import { focused, panes } from "herdr";

// A mod gets no event when its tab is shown, and its own pane id is not in props().
const POLL_MS = 250;

export function focusWhenShown(mod, handle, cx) {
  let ownPane = null, wasShown = false;
  cx.timer.every(POLL_MS, () => {
    const pane = focused()?.pane ?? null;
    // A copy starts when its pane first shows, so the first focused pane running this
    // mod is its own. Checking the mod keeps a copy reloaded while hidden from claiming
    // a terminal's pane and taking its keyboard.
    if (!ownPane && pane && panes().some((p) => p.pane === pane && p.mod === mod)) ownPane = pane;
    const shown = ownPane !== null && pane === ownPane;
    if (shown && !wasShown) handle.focus();
    wasShown = shown;
  });
}
