# ETH 地址生成器

一个本地 ETH 地址生成工具，带网页界面，可批量生成地址、私钥和助记词，并支持自定义导出格式。

默认输出格式:

```text
地址----私钥----助记词
```

对应模板:

```text
{address}----{privateKey}----{mnemonic}
```

支持的占位符:

```text
{address}
{privateKey}
{mnemonic}
{index}
```

## 一键安装

macOS / Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/wpf000705/address/refs/heads/main/remote-install.sh | sh
```

安装完成后按提示进入项目目录并启动服务。

## 手动安装

先克隆项目:

```bash
git clone https://github.com/wpf000705/address.git
cd address
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

如果 3000 端口被占用，可以指定端口。

macOS / Linux:

```bash
PORT=8080 ./start.sh
```

Windows PowerShell:

```powershell
$env:PORT=8080; .\start.ps1
```

然后打开:

```text
http://localhost:8080
```

## Docker 运行

目标电脑需要先安装 Docker。

```bash
git clone https://github.com/wpf000705/address.git
cd address
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

## 注意

私钥和助记词等同于资产控制权。请只在可信、本地或离线环境中使用，不要把生成结果发送给任何人。
