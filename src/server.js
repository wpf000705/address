import crypto from "node:crypto";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import express from "express";
import helmet from "helmet";
import { Wallet } from "ethers";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const port = Number(process.env.PORT || 3000);
const host = process.env.HOST || "0.0.0.0";
const publicDir = path.join(__dirname, "..", "public");

const DEFAULT_TEMPLATE = "{address}----{privateKey}----{mnemonic}";
const MAX_WALLETS_PER_REQUEST = 100000;
const MAX_TEMPLATE_LENGTH = 1000;
const WALLET_OBJECT_RESPONSE_LIMIT = 1000;
const GENERATION_BATCH_SIZE = 100;

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
        formAction: ["'self'"],
        upgradeInsecureRequests: null
      }
    }
  })
);
app.use(express.json({ limit: "32kb" }));
app.use(express.static(publicDir));

app.get(/(^|\/)(app\.js|styles\.css)$/, (req, res) => {
  res.sendFile(path.join(publicDir, req.params[1]));
});

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

function templateNeedsMnemonic(template) {
  return /\{mnemonic\}/.test(template);
}

function createWallet(includeMnemonic) {
  if (!includeMnemonic) {
    const privateKey = `0x${crypto.randomBytes(32).toString("hex")}`;
    const wallet = new Wallet(privateKey);

    return {
      address: wallet.address,
      privateKey: wallet.privateKey,
      mnemonic: ""
    };
  }

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

app.get(/(^|\/)api\/health$/, (_req, res) => {
  res.json({ ok: true });
});

app.post(/(^|\/)api\/wallets$/, async (req, res) => {
  try {
    const count = normalizeCount(req.body?.count ?? 1);
    const template = normalizeTemplate(req.body?.template);
    const includeMnemonic = templateNeedsMnemonic(template);
    const includeWalletObjects = count <= WALLET_OBJECT_RESPONSE_LIMIT;
    const wallets = [];
    const lines = [];

    for (let i = 0; i < count; i += 1) {
      const wallet = createWallet(includeMnemonic);
      const formatted = formatWallet(template, wallet, i + 1);
      lines.push(formatted);

      if (includeWalletObjects) {
        wallets.push({
          ...wallet,
          formatted
        });
      }

      if ((i + 1) % GENERATION_BATCH_SIZE === 0) {
        await new Promise((resolve) => setImmediate(resolve));
      }
    }

    res.json({
      count,
      template,
      wallets,
      walletsTruncated: !includeWalletObjects,
      text: lines.join("\n")
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

function getLanUrls() {
  return Object.values(os.networkInterfaces())
    .flatMap((networkInterface) => networkInterface ?? [])
    .filter((entry) => entry.family === "IPv4" && !entry.internal)
    .map((entry) => `http://${entry.address}:${port}`);
}

app.listen(port, host, () => {
  console.log(`ETH address generator listening on http://localhost:${port}`);
  for (const url of getLanUrls()) {
    console.log(`LAN access: ${url}`);
  }
});
