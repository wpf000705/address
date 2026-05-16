const DEFAULT_TEMPLATE = "{address}----{privateKey}----{mnemonic}";

const countInput = document.querySelector("#count");
const templateInput = document.querySelector("#template");
const outputInput = document.querySelector("#output");
const generateButton = document.querySelector("#generate");
const copyButton = document.querySelector("#copy");
const downloadButton = document.querySelector("#download");
const statusText = document.querySelector("#status");
const resultCount = document.querySelector("#resultCount");
const appBaseUrl = new URL(".", document.currentScript?.src || window.location.href);

let latestText = "";

function setStatus(message, isError = false) {
  statusText.textContent = message;
  statusText.classList.toggle("error", isError);
}

function setBusy(isBusy) {
  generateButton.disabled = isBusy;
  generateButton.textContent = isBusy ? "生成中..." : "生成地址";
}

function updateResult(text, count) {
  latestText = text;
  outputInput.value = text;
  resultCount.textContent = `${count} 条`;
  copyButton.disabled = !text;
  downloadButton.disabled = !text;
}

function insertToken(token) {
  const start = templateInput.selectionStart;
  const end = templateInput.selectionEnd;
  const current = templateInput.value || DEFAULT_TEMPLATE;
  templateInput.value = `${current.slice(0, start)}${token}${current.slice(end)}`;
  const nextPosition = start + token.length;
  templateInput.focus();
  templateInput.setSelectionRange(nextPosition, nextPosition);
}

async function generateWallets() {
  setBusy(true);
  setStatus("生成中");

  try {
    const response = await fetch(new URL("api/wallets", appBaseUrl), {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        count: Number(countInput.value),
        template: templateInput.value || DEFAULT_TEMPLATE
      })
    });

    const payload = await response.json();
    if (!response.ok) {
      throw new Error(payload.error || "生成失败");
    }

    updateResult(payload.text, payload.count);
    setStatus("已生成");
  } catch (error) {
    setStatus(error instanceof Error ? error.message : "生成失败", true);
  } finally {
    setBusy(false);
  }
}

async function copyResult() {
  if (!latestText) return;
  await navigator.clipboard.writeText(latestText);
  setStatus("已复制");
}

function downloadResult() {
  if (!latestText) return;
  const blob = new Blob([latestText], { type: "text/plain;charset=utf-8" });
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = `eth-wallets-${new Date().toISOString().replace(/[:.]/g, "-")}.txt`;
  link.click();
  URL.revokeObjectURL(link.href);
  setStatus("已下载");
}

document.querySelectorAll("[data-token]").forEach((button) => {
  button.addEventListener("click", () => insertToken(button.dataset.token));
});

generateButton.addEventListener("click", generateWallets);
copyButton.addEventListener("click", copyResult);
downloadButton.addEventListener("click", downloadResult);
