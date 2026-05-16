import crypto from "node:crypto";
import path from "node:path";
import { fileURLToPath } from "node:url";
import express from "express";
import helmet from "helmet";
import { Wallet } from "ethers";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const port = Number(process.env.PORT || 3000);
const publicDir = path.join(__dirname, "..", "public");

const DEFAULT_TEMPLATE = "{address}----{privateKey}----{mnemonic}";
const MAX_WALLETS_PER_REQUEST = 100;
const MAX_TEMPLATE_LENGTH = 1000;

app.disable("x-powered-by");
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'"],
        imgSrc: ["'self'", "data:"],
        connectSrc: ["'self'"],
        baseUri: ["'self'"],
        formAction: ["'self'"]
      }
    }
  })
);
app.use(express.json({ limit: "32kb" }));
app.use(express.static(publicDir));

function normalizeCount(value) {
  const count = Number(value);
  if (!Number.isInteger(count) || count < 1 || count > MAX_WALLETS_PER_REQUEST) {
    throw new Error(`count must be an integer between 1 and ${MAX_WALLETS_PER_REQUEST}`);
  }
  return count;
}

function normalizeTemplate(value) {
  if (value == null || value === "") {
    return DEFAULT_TEMPLATE;
  }
  if (typeof value !== "string") {
    throw new Error("template must be a string");
  }
  if (value.length > MAX_TEMPLATE_LENGTH) {
    throw new Error(`template must be ${MAX_TEMPLATE_LENGTH} characters or fewer`);
  }
  return value;
}

function createWallet() {
  const wallet = Wallet.createRandom({
    extraEntropy: crypto.randomBytes(32)
  });

  return {
    address: wallet.address,
    privateKey: wallet.privateKey,
    mnemonic: wallet.mnemonic?.phrase ?? ""
  };
}

function formatWallet(template, wallet, index) {
  const values = {
    address: wallet.address,
    privateKey: wallet.privateKey,
    mnemonic: wallet.mnemonic,
    index: String(index),
    line: String(index)
  };

  return template.replace(/\{(address|privateKey|mnemonic|index|line)\}/g, (_, key) => values[key]);
}

app.get("/api/health", (_req, res) => {
  res.json({ ok: true });
});

app.post("/api/wallets", (req, res) => {
  try {
    const count = normalizeCount(req.body?.count ?? 1);
    const template = normalizeTemplate(req.body?.template);
    const wallets = Array.from({ length: count }, (_unused, i) => {
      const wallet = createWallet();
      return {
        ...wallet,
        formatted: formatWallet(template, wallet, i + 1)
      };
    });

    res.json({
      count,
      template,
      wallets,
      text: wallets.map((wallet) => wallet.formatted).join("\n")
    });
  } catch (error) {
    res.status(400).json({
      error: error instanceof Error ? error.message : "Invalid request"
    });
  }
});

app.get("*", (_req, res) => {
  res.sendFile(path.join(publicDir, "index.html"));
});

app.listen(port, "0.0.0.0", () => {
  console.log(`ETH address generator listening on port ${port}`);
});
