// Shows one file's uncommitted changes as a tab in the center of the window.
// The diff logic follows the shipped `changes` mod (0.1.12).
// Props: { root: repository top level, path: relative to root, on: machine or null }
import { View, div } from "gpui-kit";
import { v_flex, h_flex, Scrollbar, v_virtual_list } from "gpui-base";
import { props, exec, readTextFile, theme, settings } from "herdr";

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

// Numbers each diff line once, so a frame only draws the rows on screen.
function diffRows(lines) {
  let old = 0, next = 0;
  return lines.map((line) => {
    const match = /^@@ -(\d+)(?:,\d+)? \+(\d+)/.exec(line);
    if (match) { old = +match[1]; next = +match[2]; return { kind: "@", text: line }; }
    const kind = line[0];
    if (kind === "-") return { kind, number: old++, text: line.slice(1) || " " };
    if (kind === "+") return { kind, number: next++, text: line.slice(1) || " " };
    if (kind === " ") { old++; return { kind, number: next++, text: line.slice(1) || " " }; }
    return { kind: "", text: line };
  });
}

export default class DiffViewer extends View {
  init(_props, cx) {
    // props() is null under `herdr-app check`, which loads the mod without a pane.
    const given = props();
    this.root = given?.root ?? null;
    this.path = given?.path ?? null;
    this.on = given?.on ?? null;
    this.rows = [];
    this.width = 300;
    if (!this.root || !this.path) { this.note = "No diff given"; return; }
    this.refresh(cx);
    cx.timer.every(REFRESH_MS, (cx) => this.refresh(cx));
  }

  git(args) {
    return exec("git", [...READ, ...args], { cwd: this.root, on: this.on });
  }

  async readLines() {
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
    const all = diff.stdout.replace(/\n$/, "").split("\n");
    const first = all.findIndex((line) => line.startsWith("@@"));
    if (first < 0) return { message: all.some((line) => line.startsWith("Binary files")) ? "Binary file changed" : "No text diff available" };
    return { lines: all.slice(first) };
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
    this.width = Math.max(300, ...shown.map((line) => line.length * 8 + 60));
  }

  row({ kind, number, text }, t) {
    if (kind === "@") return div().w_full().px(12).h(ROW_HEIGHT).flex_none().truncate().bg(t.raised).text_color(t.dim).child(text);
    const tint = kind === "+" ? t.ansi2 : kind === "-" ? t.ansi1 : null;
    return h_flex().w_full().h(ROW_HEIGHT).flex_none().gap(10)
      .when(Boolean(tint), (e) => e.bg(settings().dark ? DARK_ROW[kind] : tint + LIGHT_ROW_ALPHA))
      .child(div().w(44).flex_none().text_right().text_color(tint ?? t.dim).child(number === undefined ? "" : String(number)))
      .child(div().w(10).flex_none().font_semibold().text_color(tint ?? t.dim).child(tint ? kind : ""))
      .child(div().flex_1().min_w(0).truncate().child(text));
  }

  render() {
    const t = theme();
    return v_flex().id("diff-viewer").size_full().min_h(0).bg(t.background).text_color(t.foreground).text_size(13)
      .child(h_flex().h(30).flex_none().px(14).items_center().border_b(1).border_color(t.border)
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.dim).child(this.path ? `${this.root}/${this.path}` : "")))
      .when(Boolean(this.note), (e) => e.child(div().p(16).text_color(t.dim).child(this.note)))
      .child(div().flex_1().min_h(0).relative().font_family(settings().font_family ?? "JetBrains Mono")
        .child(div().id("viewer-diff-x").size_full().overflow_x_scrollbar()
          .child(div().w_full().min_w(this.width).h_full().child(v_virtual_list("viewer-diff", this.rows.length, ROW_HEIGHT, (i) => String(i),
            (range) => this.rows.slice(range.start, range.end).map((row) => this.row(row, t))).size_full())))
        .child(Scrollbar.vertical("viewer-diff").viewport_from_layout().absolute().inset_0()));
  }
}
