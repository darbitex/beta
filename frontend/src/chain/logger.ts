// Lightweight frontend logger with a localStorage ring buffer and an
// optional export-to-JSON keyboard shortcut. Purely runtime diagnostic —
// no remote reporting, no telemetry. Intended for reproducing user-visible
// bugs that don't show up in my sandbox: user hits issue, presses the
// export shortcut, shares the file.

export type LogLevel = "debug" | "info" | "warn" | "error";

export type LogEntry = {
  ts: number;
  level: LogLevel;
  source: string;
  message: string;
  data?: unknown;
};

const STORAGE_KEY = "darbitex.logs";
const MAX_ENTRIES = 500;

function readAll(): LogEntry[] {
  if (typeof localStorage === "undefined") return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function writeAll(entries: LogEntry[]): void {
  if (typeof localStorage === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
  } catch {
    // localStorage full / quota exceeded — drop everything and start over
    try {
      localStorage.setItem(STORAGE_KEY, "[]");
    } catch {
      /* noop */
    }
  }
}

function serializeError(err: unknown): unknown {
  if (err instanceof Error) {
    return {
      name: err.name,
      message: err.message,
      stack: err.stack?.split("\n").slice(0, 6).join("\n"),
    };
  }
  if (typeof err === "object" && err !== null) {
    try {
      return JSON.parse(JSON.stringify(err));
    } catch {
      return String(err);
    }
  }
  return err;
}

function push(entry: LogEntry): void {
  const all = readAll();
  all.push(entry);
  if (all.length > MAX_ENTRIES) all.splice(0, all.length - MAX_ENTRIES);
  writeAll(all);
}

export function logDebug(source: string, message: string, data?: unknown): void {
  const entry: LogEntry = { ts: Date.now(), level: "debug", source, message, data };
  push(entry);
  // eslint-disable-next-line no-console
  console.debug(`[${source}] ${message}`, data ?? "");
}

export function logInfo(source: string, message: string, data?: unknown): void {
  const entry: LogEntry = { ts: Date.now(), level: "info", source, message, data };
  push(entry);
  // eslint-disable-next-line no-console
  console.info(`[${source}] ${message}`, data ?? "");
}

export function logWarn(source: string, message: string, data?: unknown): void {
  const entry: LogEntry = { ts: Date.now(), level: "warn", source, message, data };
  push(entry);
  // eslint-disable-next-line no-console
  console.warn(`[${source}] ${message}`, data ?? "");
}

export function logError(source: string, message: string, err?: unknown): void {
  const entry: LogEntry = {
    ts: Date.now(),
    level: "error",
    source,
    message,
    data: serializeError(err),
  };
  push(entry);
  // eslint-disable-next-line no-console
  console.error(`[${source}] ${message}`, err ?? "");
}

export function getLogs(): LogEntry[] {
  return readAll();
}

export function clearLogs(): void {
  writeAll([]);
}

export function exportLogs(): void {
  if (typeof document === "undefined") return;
  const entries = readAll();
  const payload = {
    exported_at: new Date().toISOString(),
    user_agent: navigator.userAgent,
    count: entries.length,
    entries: entries.map((e) => ({ ...e, ts_iso: new Date(e.ts).toISOString() })),
  };
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `darbitex-logs-${new Date().toISOString().replace(/[:.]/g, "-")}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// Install a global keyboard shortcut: Ctrl+Shift+L = export logs as JSON.
// Only installs once (idempotent).
let shortcutInstalled = false;
export function installLogShortcut(): void {
  if (shortcutInstalled) return;
  if (typeof window === "undefined") return;
  window.addEventListener("keydown", (e) => {
    if (e.ctrlKey && e.shiftKey && e.key.toLowerCase() === "l") {
      e.preventDefault();
      exportLogs();
    }
  });
  shortcutInstalled = true;
}
