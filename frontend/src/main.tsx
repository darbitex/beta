import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { App } from "./App";
import { installLogShortcut, logInfo } from "./chain/logger";
import "./styles.css";

installLogShortcut();
logInfo("boot", "darbitex frontend boot");

const root = document.getElementById("root");
if (!root) throw new Error("root not found");
createRoot(root).render(
  <StrictMode>
    <App />
  </StrictMode>,
);

(window as unknown as { __dbx_mounted?: () => void }).__dbx_mounted?.();
