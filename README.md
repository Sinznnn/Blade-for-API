# Blade-for-API

API 路由 / 网关实验项目。

## 环境

- Windows + PowerShell 7
- Git 远端：`git@github.com:Sinznnn/Blade-for-API.git`（SSH，密钥 `~/.ssh/github_ed25519`）
- 提交邮箱：`s666754@163.com`

## 目录

```
.
├── .gitignore
├── README.md
└── switch-to-github.ps1    # 把本机仓库从 gitee 批量切到 github 的辅助脚本
```

## 常用命令

```powershell
git status
git add .
git commit -m "feat: xxx"
git push
```

## switch-to-github.ps1

```powershell
# 预演
.\switch-to-github.ps1 -GithubUser Sinznnn -DryRun
# 真改
.\switch-to-github.ps1 -GithubUser Sinznnn
```
