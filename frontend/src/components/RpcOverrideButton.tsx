import { useEffect, useRef, useState } from "react";

// UI wrapper over the darbitex.rpcOverride localStorage key. Lets a dev
// paste a private RPC URL (QuickNode, Alchemy, etc.) without touching the
// browser devtools console. The URL is saved ONLY in this browser's
// localStorage — never uploaded anywhere, never committed to git, not
// visible to other users of darbitex.wal.app.

const STORAGE_KEY = "darbitex.rpcOverride";

function readOverride(): string[] {
  if (typeof localStorage === "undefined") return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed)) return parsed.filter((x): x is string => typeof x === "string");
  } catch {
    // ignore
  }
  return [];
}

export function RpcOverrideButton() {
  const [open, setOpen] = useState(false);
  const [text, setText] = useState<string>("");
  const [saved, setSaved] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setText(readOverride().join("\n"));
  }, [open]);

  useEffect(() => {
    if (!open) return;
    function onClick(e: MouseEvent) {
      if (!rootRef.current) return;
      if (!rootRef.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", onClick);
    return () => document.removeEventListener("mousedown", onClick);
  }, [open]);

  function save() {
    const lines = text
      .split(/\r?\n/)
      .map((s) => s.trim())
      .filter((s) => s.startsWith("http"));
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(lines));
      setSaved(true);
      setTimeout(() => setSaved(false), 1200);
    } catch {
      // ignore
    }
  }

  function clear() {
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      // ignore
    }
    setText("");
    setSaved(true);
    setTimeout(() => setSaved(false), 1200);
  }

  function reload() {
    window.location.reload();
  }

  const active = readOverride().length > 0;

  return (
    <div className="slippage-wrap" ref={rootRef}>
      <button
        type="button"
        className={`slippage-btn${active ? " rpc-active" : ""}`}
        onClick={() => setOpen((o) => !o)}
        title="RPC override (dev)"
        aria-label="RPC override"
      >
        RPC
      </button>
      {open && (
        <div className="slippage-panel" style={{ minWidth: 320 }}>
          <div className="slippage-panel-title">RPC override (dev)</div>
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="https://your-quicknode-url/v1 (one URL per line)"
            rows={4}
            style={{
              width: "100%",
              background: "#0a0a0a",
              border: "1px solid #333",
              color: "#fff",
              padding: "8px",
              borderRadius: "6px",
              fontFamily: "inherit",
              fontSize: "11px",
              resize: "vertical",
              marginBottom: "8px",
            }}
          />
          <div style={{ display: "flex", gap: "6px", marginBottom: "8px" }}>
            <button type="button" className="slippage-apply" onClick={save}>
              Save
            </button>
            <button type="button" className="slippage-apply" onClick={clear}>
              Clear
            </button>
            <button type="button" className="slippage-apply" onClick={reload}>
              Reload
            </button>
          </div>
          {saved && <div style={{ fontSize: 10, color: "#ff8800" }}>Saved. Reload to apply.</div>}
          <div className="slippage-hint">
            URL disimpan di browser ini saja (localStorage). Tidak ke-push, tidak visible ke user lain. Aktif: prepended ke RPC pool, dicoba pertama di rotasi.
          </div>
        </div>
      )}
    </div>
  );
}
