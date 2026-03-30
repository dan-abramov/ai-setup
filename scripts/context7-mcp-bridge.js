#!/usr/bin/env node
"use strict";

const { spawn } = require("node:child_process");

const target = process.argv[2];
if (!target) {
  console.error("Usage: context7-mcp-bridge.js <path-to-context7-index.js>");
  process.exit(1);
}

const child = spawn("node", [target], {
  stdio: ["pipe", "pipe", "pipe"],
});

child.stderr.on("data", (chunk) => process.stderr.write(chunk));
child.on("exit", (code, signal) => {
  if (signal) process.kill(process.pid, signal);
  process.exit(code ?? 0);
});

let parentMode = null; // "line" | "header"
let parentBuf = Buffer.alloc(0);
let childBuf = "";

function forwardToChild(jsonText) {
  child.stdin.write(jsonText + "\n");
}

function writeToParent(jsonText) {
  if (parentMode === "header") {
    const len = Buffer.byteLength(jsonText, "utf8");
    process.stdout.write(`Content-Length: ${len}\r\n\r\n${jsonText}`);
    return;
  }
  process.stdout.write(jsonText + "\n");
}

function parseHeaderFramed() {
  while (true) {
    const sep = parentBuf.indexOf("\r\n\r\n");
    if (sep === -1) return;

    const header = parentBuf.toString("utf8", 0, sep);
    const m = /content-length:\s*(\d+)/i.exec(header);
    if (!m) {
      parentBuf = parentBuf.subarray(sep + 4);
      continue;
    }

    const len = Number(m[1]);
    const start = sep + 4;
    const end = start + len;
    if (parentBuf.length < end) return;

    const json = parentBuf.toString("utf8", start, end);
    parentBuf = parentBuf.subarray(end);
    forwardToChild(json);
  }
}

function parseLineFramed() {
  while (true) {
    const nl = parentBuf.indexOf(0x0a); // \n
    if (nl === -1) return;
    const line = parentBuf.toString("utf8", 0, nl).replace(/\r$/, "");
    parentBuf = parentBuf.subarray(nl + 1);
    if (line.trim()) forwardToChild(line);
  }
}

process.stdin.on("data", (chunk) => {
  if (!parentMode) {
    const sample = chunk.toString("utf8");
    parentMode = /^\s*Content-Length:/i.test(sample) ? "header" : "line";
  }

  parentBuf = Buffer.concat([parentBuf, chunk]);
  if (parentMode === "header") parseHeaderFramed();
  else parseLineFramed();
});

process.stdin.on("end", () => {
  child.stdin.end();
});

child.stdout.on("data", (chunk) => {
  childBuf += chunk.toString("utf8");
  while (true) {
    const idx = childBuf.indexOf("\n");
    if (idx === -1) break;
    const line = childBuf.slice(0, idx).replace(/\r$/, "");
    childBuf = childBuf.slice(idx + 1);
    if (line.trim()) writeToParent(line);
  }
});
