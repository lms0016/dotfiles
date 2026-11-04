// A read-only file reader that opens as a tab in the center of the window.
// Markdown is rendered; everything else is shown as highlighted code.
// Props: { file: absolute path, on: machine or null }
import { View, div } from "gpui-kit";
import { v_flex, h_flex, Editor, EditorState, TextView } from "gpui-base";
import { props, readTextFile, theme, settings } from "herdr";
import { focusWhenShown } from "./focus-on-show.js";

const LANG = { ts: "js", tsx: "js", mts: "js", cts: "js", jsx: "js", mjs: "js", toml: "yaml", jsonc: "json", svelte: "html", vue: "html" };
const MAX_CHARS = 400000;
const REFRESH_MS = 10000;

export default class FileViewer extends View {
  init(_props, cx) {
    // `mod:file-viewer` keys only apply while this mod holds the keyboard.
    this.handle = cx.focus_handle();
    focusWhenShown("file-viewer", this.handle, cx);
    // props() is null under `herdr-app check`, which loads the mod without a pane.
    this.file = props()?.file ?? null;
    this.on = props()?.on ?? null;
    if (!this.file) { this.error = "No file given"; return; }
    this.refresh(cx);
    cx.timer.every(REFRESH_MS, (cx) => this.refresh(cx));
  }

  refresh(cx) {
    if (this.loading) return;
    this.loading = true;
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(this.file, { on: this.on });
        // Rebuilding the view resets the scroll position, so only do it when the file changed.
        if (text === this.text && this.text !== undefined) return;
        this.text = text;
        this.clear();
        if (text === null) this.error = "This file is no longer available";
        else if (text.includes("\0")) this.error = "Binary file: no text preview";
        else this.present(text);
        cx.notify();
      } catch {
        if (this.error) return;
        this.clear();
        this.text = undefined;
        this.error = "Cannot open this file (binary, over 1 MiB, or unreadable)";
        cx.notify();
      } finally {
        this.loading = false;
      }
    });
  }

  clear() {
    this.code?.release();
    this.code = null;
    this.markdown = null;
    this.error = null;
  }

  present(text) {
    const ext = this.file.includes(".") ? this.file.split(".").pop().toLowerCase() : "txt";
    const value = text.length > MAX_CHARS ? text.slice(0, MAX_CHARS) + "\n… (file truncated)" : text;
    if (ext === "md" || ext === "markdown") { this.markdown = value; return; }
    const t = theme();
    this.code = EditorState.new({
      language: LANG[ext] ?? ext, readonly: true, value,
      font_family: settings().font_family,
      syntax: { keyword: t.ansi5, string: t.ansi2, comment: t.dim, function: t.ansi4, type: t.ansi3, number: t.ansi1, constant: t.ansi6 },
    });
  }

  async close() {
    this.code?.release();
  }

  render() {
    const t = theme();
    const body = this.markdown !== null && this.markdown !== undefined
      ? div().id("viewer-scroll").flex_1().min_h(0).overflow_y_scrollbar().px(24).py(16)
          .child(TextView.markdown("viewer-markdown", this.markdown).selectable(true))
      : this.code
        ? Editor.new(this.code).flex_1().min_h(0)
        : div().p(16).text_color(t.dim).child(this.error ?? "Loading file…");
    return v_flex().id("file-viewer").size_full().min_h(0).bg(t.background).text_color(t.foreground).text_size(14).track_focus(this.handle)
      .child(h_flex().h(30).flex_none().px(14).items_center().border_b(1).border_color(t.border)
        .child(div().flex_1().min_w(0).truncate().text_size(12).text_color(t.dim).child(this.file ?? "")))
      .child(body);
  }
}
