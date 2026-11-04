import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { spaces, panes, focused, exec, watchFolder, theme } from "herdr";
import { openTab } from "./open-tab.js";

// A mod pane has no folder. Without this, focusing a viewer tab moves the list
// to the space's folder, which can be a different repository than the terminal's.
const lastCwd = new Map();

function location() {
  const space = spaces().find((s) => s.active), f = focused();
  const pane = f?.pane ? panes().find(p => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  const live = pane?.cwd || f?.cwd;
  if (live && space) lastCwd.set(space.id, live);
  return { cwd: live || lastCwd.get(space?.id) || space?.folder, on };
}
const key = () => JSON.stringify(location());
// Reads write nothing under .git (no index refresh or lock, no fsmonitor cookie):
// the folder watch would see it, and every refresh would start the next one.
const READ = ["--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "diff.autoRefreshIndex=false"];
// Branch mode compares against the first of these that exists and is not the current branch,
// so develop compares against main, matching the PR flow topic -> develop -> main.
const BASE_CANDIDATES = ["origin/develop", "develop", "origin/main", "main", "origin/master", "master"];
const MAX_FILES = 1000;

export default class Changes extends View {
  init(_props, cx) {
    this.mode = "working"; this.base = null; this.commits = 0;
    this.files = []; this.message = ""; this.handle = cx.focus_handle();
    this.input = InputState.new({ placeholder: "Commit message" });
    this.input.on("change", (_e, cx) => {
      const hadMessage = Boolean(this.message.trim());
      this.message = this.input.value();
      if (hadMessage !== Boolean(this.message.trim())) cx.notify();
    });
    this.input.on("submit", (_e, cx) => this.commit(cx));
    this.input.on("focus", (_e, cx) => { this.typing = true; cx.notify(); });
    this.input.on("blur", (_e, cx) => { this.typing = false; cx.notify(); });
    this.refresh(cx);
    cx.timer.every(10000, (cx) => this.refresh(cx));
  }

  watch(root, cx) {
    if (this.on || this.watched === root) return;
    this.watched = root;
    cx.spawn(async (cx) => {
      try {
        while (this.watched === root) {
          await watchFolder(root);
          if (this.watched === root) this.refresh(cx);
        }
      } catch { this.watched = null; }
    });
  }

  refresh(cx) {
    if (this.loading || this.busy) return;
    const { cwd, on } = location(), context = key();
    if (context !== this.context) {
      this.context = context; this.root = null; this.files = []; this.base = null; this.commits = 0;
      this.message = ""; this.input.set_value(""); this.error = null; this.note = null; this.watched = null; this.limited = false;
    }
    if (!cwd) return;
    this.loading = true;
    const mode = this.mode;
    cx.spawn(async (cx) => {
      try {
        const top = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on });
        if (key() !== context) return;
        if (top.code !== 0) { this.root = null; this.files = []; this.error = "Not a git repository"; return; }
        const root = top.stdout.trim(), git = (args) => exec("git", [...READ, ...args], { cwd: root, on });
        if (mode === "branch") {
          const branch = await this.readBranch(git);
          if (key() !== context || this.mode !== mode) return;
          this.root = root; this.on = on; this.error = null; Object.assign(this, branch);
          this.watch(root, cx);
          return;
        }
        const status = await git(["status", "--porcelain=v1", "-z", "--no-renames", "--untracked-files=all"]);
        if (status.code !== 0) throw new Error(status.stderr);
        const head = await git(["rev-parse", "--verify", "HEAD"]);
        const stats = {};
        const results = head.code === 0 ? [await git(["diff", "HEAD", "--numstat", "-z", "--no-renames"])] : [await git(["diff", "--cached", "--numstat", "-z", "--no-renames"]), await git(["diff", "--numstat", "-z", "--no-renames"])];
        for (const result of results) {
          if (result.code !== 0) throw new Error(result.stderr);
          for (const entry of result.stdout.split("\0")) {
            const [a, d, ...parts] = entry.split("\t");
            if (!parts.length) continue;
            const path = parts.join("\t"), old = stats[path] ?? { add: 0, del: 0 };
            stats[path] = { add: old.add + (Number(a) || 0), del: old.del + (Number(d) || 0), binary: a === "-" };
          }
        }
        const files = [];
        const entries = status.stdout.split("\0").filter(Boolean);
        for (const entry of entries.slice(0, 1000)) {
          const xy = entry.slice(0, 2), path = entry.slice(3), fresh = xy === "??";
          const conflict = xy.includes("U") || xy === "AA" || xy === "DD";
          const s = conflict ? "U" : xy.includes("D") ? "D" : fresh || xy.includes("A") ? "A" : "M";
          const stat = stats[path] ?? { add: 0, del: 0 };
          files.push({ path, status: s, fresh, ...stat });
        }
        if (key() !== context || this.mode !== mode) return;
        this.root = root; this.on = on; this.files = files; this.limited = entries.length > 1000; this.error = null;
        this.watch(root, cx);
      } catch (e) { if (key() === context && this.mode === mode) this.error = String(e); }
      finally {
        this.loading = false;
        // A mode switch during this load was skipped by refresh(), so run it now.
        if (this.mode !== mode) this.refresh(cx);
        cx.notify();
      }
    });
  }

  async readBranch(git) {
    const current = (await git(["branch", "--show-current"])).stdout.trim();
    let base = null;
    for (const ref of BASE_CANDIDATES) {
      if (ref.replace(/^origin\//, "") === current) continue;
      if ((await git(["rev-parse", "--verify", "--quiet", ref])).code === 0) { base = ref; break; }
    }
    if (!base) return { base: null, commits: 0, files: [], limited: false };
    // Three dots: from the merge base to HEAD, the same set of changes a pull request shows.
    const range = `${base}...HEAD`;
    const [names, numstat, commits] = [
      await git(["diff", range, "--name-status", "-z", "--no-renames"]),
      await git(["diff", range, "--numstat", "-z", "--no-renames"]),
      await git(["rev-list", "--count", `${base}..HEAD`]),
    ];
    for (const result of [names, numstat, commits]) if (result.code !== 0) throw new Error(result.stderr);
    const stats = {};
    for (const entry of numstat.stdout.split("\0")) {
      const [a, d, ...parts] = entry.split("\t");
      if (parts.length) stats[parts.join("\t")] = { add: Number(a) || 0, del: Number(d) || 0, binary: a === "-" };
    }
    const fields = names.stdout.split("\0").filter(Boolean), files = [];
    for (let i = 0; i + 1 < fields.length; i += 2) files.push({ path: fields[i + 1], status: fields[i][0], add: 0, del: 0, ...stats[fields[i + 1]] });
    return { base, commits: Number(commits.stdout.trim()) || 0, files: files.slice(0, MAX_FILES), limited: files.length > MAX_FILES };
  }

  setMode(mode, cx) {
    if (this.mode === mode) return;
    this.mode = mode; this.base = null; this.commits = 0; this.files = []; this.error = null; this.note = null; this.limited = false;
    this.refresh(cx);
    cx.notify();
  }

  pick(path) {
    const space = spaces().find((s) => s.active)?.id, name = path.split("/").pop();
    if (this.mode === "branch") {
      openTab(`branch:${this.on ?? ""}:${this.base}:${this.root}/${path}`, { name: `${name} (branch)`, space, mod: "diff-viewer", props: { root: this.root, path, on: this.on, base: this.base } });
    } else {
      openTab(`diff:${this.on ?? ""}:${this.root}/${path}`, { name: `${name} (diff)`, space, mod: "diff-viewer", props: { root: this.root, path, on: this.on } });
    }
  }

  emptyText() {
    if (this.error) return this.error;
    if (this.loading) return "Loading changes…";
    if (!this.root) return "No folder";
    if (this.mode !== "branch") return "No uncommitted changes";
    return this.base ? `No changes vs ${this.base}` : "No base branch (develop, main or master)";
  }

  modeButton(mode, label, t) {
    const active = this.mode === mode;
    return div().id(`mode-${mode}`).px(10).py(3).rounded(6).text_size(12).cursor_pointer()
      .text_color(active ? t.foreground : t.muted).when(active, (e) => e.bg(t.selected)).hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => this.setMode(mode, cx)).child(label);
  }

  commit(cx) {
    if (!this.message.trim() || !this.root || this.busy || this.loading || this.context !== key()) return;
    const root = this.root, on = this.on, context = this.context, message = this.message.trim();
    this.busy = true; this.note = null;
    cx.spawn(async (cx) => {
      try {
        for (const args of [["add", "-A"], ["commit", "-m", message]]) {
          const r = await exec("git", args, { cwd: root, on });
          if (r.code !== 0) throw new Error((r.stderr || r.stdout).trim());
        }
        if (key() === context) { this.message = ""; this.input.set_value(""); }
      } catch (e) { if (key() === context) this.note = `Commit failed: ${e}`; }
      finally { this.busy = false; this.refresh(cx); cx.notify(); }
    });
    cx.notify();
  }

  render(cx) {
    if (key() !== this.context) this.refresh(cx);
    const t = theme(), add = this.files.reduce((n, f) => n + f.add, 0), del = this.files.reduce((n, f) => n + f.del, 0);
    const enabled = Boolean(this.message.trim() && this.root && !this.busy && !this.loading);
    return v_flex().id("changes").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13).track_focus(this.handle)
      .on_key_down((e, cx) => {
        if (e.key === "escape" && this.typing) { this.typing = false; this.handle.focus(); cx.stop_propagation(); cx.notify(); }
      })
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Changes"))
        .child(div().px(5).py(1).rounded(4).border_1().border_color(t.border).text_size(10).text_color(t.muted).child(`${this.files.length} files`))
        .child(div().flex_1()).child(div().text_size(11).text_color(t.ansi2).child(`+${add}`)).child(div().text_size(11).text_color(t.ansi1).child(`−${del}`)))
      .child(h_flex().h(36).flex_none().px(8).gap(4).items_center().border_b(1).border_color(t.border)
        .child(this.modeButton("working", "Uncommitted", t)).child(this.modeButton("branch", "Branch", t))
        .child(div().flex_1().min_w(0).truncate().text_right().pr(6).text_size(11).text_color(t.dim)
          .child(this.mode === "branch" && this.base ? `vs ${this.base} · ${this.commits} ${this.commits === 1 ? "commit" : "commits"}` : "")))
      .child(v_flex().id("changes-list").flex_1().min_h(0).overflow_y_scrollbar().p(6).children(this.files.map((f) => {
        const parts = f.path.split("/"), name = parts.pop();
        return h_flex().id(`change-${f.path}`).h(28).flex_none().px(8).gap(8).items_center().rounded(7).cursor_pointer().hover((s) => s.bg(t.hover)).on_click(() => this.pick(f.path))
          .child(div().w(14).text_size(11).text_color(f.status === "A" ? t.ansi2 : f.status === "D" ? t.ansi1 : f.status === "U" ? t.ansi1 : t.blocked).child(f.status))
          .child(h_flex().flex_1().min_w(0).child(div().text_color(t.dim).truncate().child(parts.length ? parts.join("/") + "/" : "")).child(div().max_w(260).min_w(0).truncate().child(name)))
          .when(f.add > 0, (e) => e.child(div().text_size(11).text_color(t.ansi2).child(`+${f.add}`))).when(f.del > 0, (e) => e.child(div().text_size(11).text_color(t.ansi1).child(`−${f.del}`)));
      })).when(!this.files.length, (e) => e.child(div().p(8).text_color(t.dim).child(this.emptyText()))))
      .when(this.limited, el => el.child(div().px(12).py(4).text_size(11).text_color(t.dim).child("Showing the first 1,000 changed files")))
      .when(Boolean(this.note), (e) => e.child(div().px(10).pb(8).text_size(11).text_color(t.ansi1).child(this.note)))
      .when(this.mode === "working", (e) => e.child(h_flex().flex_none().p(10).gap(8).border_t(1).border_color(t.border)
        .child(div().id("commit-message").flex_1().min_w(0).h(32).px(10).flex().items_center().rounded(8).border_1().border_color(this.typing ? t.accent : t.border).cursor_text().on_mouse_down("left", (_e, cx) => cx.stop_propagation()).child(Input.new(this.input).h_full().text_size(12).text_color(t.foreground)))
        .child(div().id("commit").h(32).px(14).flex().items_center().rounded(8).bg(enabled ? t.solid : t.raised).text_color(enabled ? t.solid_foreground : t.dim).text_size(12).when(enabled, (e) => e.cursor_pointer()).on_click((_e, cx) => this.commit(cx)).child(this.busy ? "Committing…" : "Commit"))));
  }
}
