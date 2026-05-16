# ETH 地址生成器

一个带前端的 Docker 化 ETH 地址生成工具。默认输出格式:

```text
地址----私钥----助记词
```

实际模板为:

```text
{address}----{privateKey}----{mnemonic}
```

## 运行

```bash
docker compose up --build
```

打开:

```text
http://localhost:3000
```

## 自定义格式

前端支持这些占位符:

```text
{address}
{privateKey}
{mnemonic}
{index}
```

示例:

```text
第{index}个: {address} | {privateKey} | {mnemonic}
```

## 本地开发

```bash
npm install
npm run dev
```

## Git 仓库方式部署

推荐把这个目录提交到 Git 仓库，其他电脑直接 clone:

```bash
git clone <你的仓库地址>
cd CreateAddress
```

macOS / Linux:

```bash
./install.sh
./start.sh
```

Windows PowerShell:

```powershell
.\install.ps1
.\start.ps1
```

启动后打开:

```text
http://localhost:3000
```

如果 3000 端口被占用，可以指定端口:

macOS / Linux:

```bash
PORT=8080 ./start.sh
```

Windows PowerShell:

```powershell
$env:PORT=8080; .\start.ps1
```

然后打开 `http://localhost:8080`。

Git 仓库里应提交源码、`package.json`、`package-lock.json`、Docker 配置和启动脚本；不要提交 `node_modules/`、`dist/`、`.env` 等本机文件。

## 远程一键安装脚本

如果你想做成类似:

```bash
curl -fsSL https://raw.githubusercontent.com/<用户名>/<仓库名>/refs/heads/main/remote-install.sh | sh
```

需要先修改 [remote-install.sh](remote-install.sh) 里的默认仓库地址:

```sh
REPO_URL="${REPO_URL:-https://github.com/wpf000705/address.git}"
```

把 `YOUR_GITHUB_USERNAME` 改成你的 GitHub 用户名，然后提交到 GitHub。

也可以不改文件，执行时临时指定:

```bash
curl -fsSL https://raw.githubusercontent.com/wpf000705/address/refs/heads/main/remote-install.sh | REPO_URL=https://github.com/wpf000705/address.git sh
```

不建议默认使用 `sudo bash`，因为本项目只需要安装 npm 依赖，不需要 root 权限。只有要安装到 `/opt`、写系统服务、开机自启时才需要 sudo。

## 注意

私钥和助记词等同于资产控制权。请只在可信环境中使用，不要把生成结果发送给任何人。

## 打包到其他电脑使用

在当前电脑执行:

```bash
npm run package
```

生成文件在 `dist/` 目录:

```text
create-eth-address-1.0.0.tar.gz
create-eth-address-1.0.0.zip
```

把 `.zip` 或 `.tar.gz` 拷贝到其他电脑，解压后进入目录运行。

### 推荐方式: Docker 运行

目标电脑需要先安装 Docker Desktop 或 Docker Engine。

```bash
docker compose up --build
```

打开:

```text
http://localhost:3000
```

停止服务:

```bash
docker compose down
```

### 备用方式: Node.js 运行

目标电脑需要 Node.js 20 或更高版本。

```bash
npm ci
npm start
```

打开:

```text
http://localhost:3000
```

如需更换端口:

```bash
PORT=8080 npm start
```

然后打开 `http://localhost:8080`。

## 打包内容说明

打包文件包含源码、前端页面、Docker 配置和 `package-lock.json`。不会包含 `node_modules/`，目标电脑会通过 Docker 构建或 `npm ci` 重新安装对应依赖。
