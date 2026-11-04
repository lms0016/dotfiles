// Shows one file's uncommitted changes as a tab in the center of the window.
// The diff logic follows the shipped `changes` mod (0.1.12).
// Props: { root: repository top level, path: relative to root, on: machine or null,
//          base: optional ref; when set, shows base...HEAD instead of uncommitted changes }
import { View, div, list } from "gpui-kit";
import { v_flex, h_flex, Scrollbar } from "gpui-base";
import { props, exec, readTextFile, theme, settings } from "herdr";
import { focusWhenShown } from "./focus-on-show.js";

// Reads write nothing under .git (no index refresh or lock, no fsmonitor cookie).
const READ = ["--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "diff.autoRefreshIndex=false"];
const REFRESH_MS = 10000;
const MAX_LINES = 5000;
const MAX_LINE_CHARS = 4000;
const ROW_HEIGHT = 20;
// Dark rows use Claude Code's diff colors, measured from its output. They read better
// than any alpha of the theme's muted ansi colors because they are saturated, not bright.
const DARK_ROW = { "+": "#022800", "-": "#3d0100" };
const LIGHT_ROW_ALPHA = "48";

// Turns a unified diff into side-by-side rows: each run of removed lines is paired with
// the added lines that follow it, and the shorter side gets empty cells.
function diffRows(lines) {
  const rows = [];
  let old = 0, next = 0, removed = [], added = [], last = [];
  const flush = () => {
    for (let i = 0; i < Math.max(removed.length, added.length); i++) rows.push({ left: removed[i] ?? null, right: added[i] ?? null });
    removed = []; added = [];
  };
  for (const line of lines) {
    const match = /^@@ -(\d+)(?:,\d+)? \+(\d+)/.exec(line);
    const kind = line[0], text = line.slice(1) || " ";
    if (match) {
      flush(); old = +match[1]; next = +match[2];
      rows.push({ header: line });
    } else if (kind === "-") {
      last = [{ kind, number: old++, text }]; removed.push(last[0]);
    } else if (kind === "+") {
      last = [{ kind, number: next++, text }]; added.push(last[0]);
    } else if (kind === " ") {
      flush();
      last = [{ kind, number: old++, text }, { kind, number: next++, text }];
      rows.push({ left: last[0], right: last[1] });
    } else if (kind === "\\") {
      // "\ No newline at end of file" describes the line before it. Keeping it as its own
      // row would split a removed line from the added line it pairs with.
      for (const cell of last) cell.text += "  (no newline at end of file)";
    } else {
      flush();
      rows.push({ header: line });
    }
  }
  flush();
  return rows;
}

export default class DiffViewer extends View {
  init(_props, cx) {
    // `mod:diff-viewer` keys only apply while this mod holds the keyboard.
    this.handle = cx.focus_handle();
    focusWhenShown("diff-viewer", this.handle, cx);
    // props() is null under `herdr-app check`, which loads the mod without a pane.
    const given = props();
    this.root = given?.root ?? null;
    this.path = given?.path ?? null;
    this.on = given?.on ?? null;
    this.base = given?.base ?? null;
    this.rows = [];
    this.generation = 0;
    if (!this.root || !this.path) { this.note = "No diff given"; return; }
    this.refresh(cx);
    cx.timer.every(REFRESH_MS, (cx) => this.refresh(cx));
  }

  git(args) {
    return exec("git", [...READ, ...args], { cwd: this.root, on: this.on });
  }

  async readBranchLines() {
    const diff = await this.git(["diff", `${this.base}...HEAD`, "--no-ext-diff", "--no-textconv", "--no-color", "--", this.path]);
    if (diff.code !== 0) throw new Error(diff.stderr);
    if (!diff.stdout.trim()) return { message: `No changes in this file vs ${this.base}` };
    return this.parseDiff(diff.stdout);
  }

  parseDiff(stdout) {
    const all = stdout.replace(/\n$/, "").split("\n");
    const first = all.findIndex((line) => line.startsWith("@@"));
    if (first < 0) return { message: all.some((line) => line.startsWith("Binary files")) ? "Binary file changed" : "No text diff available" };
    return { lines: all.slice(first) };
  }

  async readLines() {
    if (this.base) return this.readBranchLines();
    const status = await this.git(["status", "--porcelain=v1", "-z", "--no-renames", "--untracked-files=all", "--", this.path]);
    if (status.code !== 0) throw new Error(status.stderr);
    const xy = status.stdout.slice(0, 2);
    if (!xy) return { message: "No uncommitted changes in this file" };
    const head = await this.git(["rev-parse", "--verify", "HEAD"]);
    if (xy === "??" || (head.code !== 0 && xy.includes("A"))) {
      const text = await readTextFile(`${this.root}/${this.path}`, { on: this.on }).catch(() => null);
      if (text === null) return { message: "Cannot preview this file (binary, too large, or unreadable)" };
      if (text.includes("\0")) return { message: "Binary file: no text diff" };
      const added = text.replace(/\n$/, "").split("\n");
      return { lines: [`@@ -0,0 +1,${added.length} @@`, ...added.map((line) => `+${line}`)] };
    }
    const diff = await this.git(["diff", ...(head.code === 0 ? ["HEAD"] : []), "--no-ext-diff", "--no-textconv", "--no-color", "--", this.path]);
    if (diff.code !== 0) throw new Error(diff.stderr);
    return this.parseDiff(diff.stdout);
  }

  refresh(cx) {
    if (this.loading) return;
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        const { lines = [], message = null } = await this.readLines();
        const raw = JSON.stringify([lines, message]);
        // Replacing the rows disturbs the scroll position, so only do it when the diff changed.
        if (raw === this.raw) return;
        this.raw = raw;
        this.note = message;
        this.show(lines);
        cx.notify();
      } catch (e) {
        const note = `Cannot preview this diff: ${e}`;
        if (note === this.note) return;
        this.raw = null;
        this.note = note;
        this.show([]);
        cx.notify();
      } finally {
        this.loading = false;
      }
    });
  }

  show(lines) {
    const shown = lines.slice(0, MAX_LINES).map((line) => line.length > MAX_LINE_CHARS ? line.slice(0, MAX_LINE_CHARS) + "… (line truncated)" : line);
    if (lines.length > MAX_LINES) shown.push(`… (diff truncated at ${MAX_LINES} lines)`);
    this.rows = diffRows(shown);
    // A list keeps its scroll position and measured heights by id, and one that grows from
    // empty opens at the bottom. A new id per diff starts it at the top with the right heights.
    this.generation++;
  }

  cell(cell, t) {
    const base = div().flex_1().min_w(0).min_h(ROW_HEIGHT);
    if (!cell) return base.bg(t.raised);
    const tint = cell.kind === "+" ? t.ansi2 : cell.kind === "-" ? t.ansi1 : null;
    return base.flex().flex_row().gap(10)
      .when(Boolean(tint), (e) => e.bg(settings().dark ? DARK_ROW[cell.kind] : tint + LIGHT_ROW_ALPHA))
      .child(div().w(44).flex_none().text_right().text_color(tint ?? t.dim).child(String(cell.number)))
      .child(div().w(10).flex_none().font_semibold().text_color(tint ?? t.dim).child(tint ? cell.kind : ""))
      .child(div().flex_1().min_w(0).pr(8).child(cell.text));
  }

  row({ header, left, right }, t) {
    if (header !== undefined) return div().w_full().px(12).h(ROW_HEIGHT).truncate().bg(t.raised).text_color(t.dim).child(header);
    return h_flex().w_full().items_stretch()
      .child(this.cell(left, t))
      .child(div().w(1).flex_none().bg(t.border))
      .child(this.cell(right, t));
  }

  render() {
    const t = theme(), listId = `viewer-diff-${this.generation}`;
    return v_flex().id("diff-viewer").size_full().min_h(0).bg(t.background).text_color(t.foreground).text_size(13).track_focus(this.handle)
      .child(h_flex().h(30).flex_none().px(14).items_center().border_b(1).border_color(t.border)
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.dim).child(this.path ? `${this.root}/${this.path}${this.base ? `  (vs ${this.base})` : ""}` : "")))
      .when(Boolean(this.note), (e) => e.child(div().p(16).text_color(t.dim).child(this.note)))
      .child(div().flex_1().min_h(0).relative().font_family(settings().font_family ?? "JetBrains Mono")
        .child(list(listId, this.rows.length, (i) => String(i), (i) => this.row(this.rows[i], t)).size_full())
        .child(Scrollbar.vertical(listId).absolute().inset_0()));
  }
}
