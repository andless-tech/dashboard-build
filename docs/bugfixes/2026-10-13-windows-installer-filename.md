# Windows 安装包文件名去除空格

用户收到的安装包为 `Andless Dashboard_0.0.0_x64-setup.exe`，要求文件名不要包含空格。
Tauri 根据产品显示名 `Andless Dashboard` 生成文件名，构建工作流此前直接上传 NSIS 产物。

在 Windows 构建结束、上传前，将安装包文件名中的空格替换为短横线。
版本、架构及文件内容保持一致，安装程序中的应用名称和安装路径不变。
上传与发布继续使用原有通配符，因此均能获取改名后的文件。
macOS、Linux 不执行该步骤。

验证：在 Linux 临时目录执行工作流中的 Bash 步骤，检查带空格和不带空格的文件，
重复执行后文件名稳定、内容一致；当前实际 Windows 安装包重命名前后 SHA256 一致。
未重新构建 Windows；Windows runner 的 Git Bash 执行仍待下次构建验证。
