# Boris Cherny 的 Claude Code 使用 Tips

**作者**：Boris Cherny (@bcherny)  
**职位**：Claude Code 创建者（Anthropic）  
**发布时间**：2026 年 1 月 31 日  
**原文线程**：https://x.com/bcherny/status/2017742759218794768

> 我是 Boris，我创建了 Claude Code。我想快速分享一些使用 Claude Code 的 tips，这些都是直接来自 Claude Code 团队的经验。  
> 团队使用 Claude 的方式和我个人使用的方式不太一样。  
> 记住：使用 Claude Code **没有唯一正确的方法** —— 每个人的设置都不同。你应该多做实验，找到适合自己的方式！

## 1. 多线程并行工作（Do more in parallel）

一次性启动 **3–5 个 git worktree**，每个 worktree 运行一个独立的 Claude 会话。这是团队公认的最大生产力提升。  

我个人使用多个 git checkout，但 Claude Code 团队大多数人更喜欢 worktrees —— 这也是 @amorriscode 为 Claude Desktop App 内置原生支持的原因！

一些人会给 worktree 命名，并设置 shell alias（例如 `za`、`zb`、`zc`），一键切换。还有人专门建了一个只读的 “analysis” worktree，用于查看日志和运行 BigQuery。

## 2. 复杂任务先进入计划模式（Start every complex task in plan mode）

把精力全放在写计划上，让 Claude 一次性完成实现（1-shot the implementation）。

有人让一个 Claude 写计划，再启动第二个 Claude 以 Staff Engineer 身份审查计划。  
一旦任务出问题，立刻切回计划模式重新规划，不要硬推。  
明确告诉 Claude 在验证步骤时也进入计划模式，而不仅仅是构建阶段。

## 3. 持续投资你的 Claude 知识库（Invest in your CLAUDE.md）

每次纠正 Claude 的错误后，都在结尾加上：  
**“Update your CLAUDE.md so you don’t make that mistake again.”**

Claude 非常擅长为自己写规则。  
无情地编辑你的 **CLAUDE.md**，持续迭代，直到 Claude 的错误率明显下降。  

一位工程师让 Claude 为每个任务/项目维护一个 `notes/` 目录，每次 PR 后更新，然后在项目根目录的 **CLAUDE.md** 中指向这个 notes 目录。

**小贴士**：  
- **CLAUDE.md** 应放在项目根目录并提交到 git（可团队共享）。  
- Claude Code 会在每个会话开始时自动读取它，作为长期指令/记忆。

## 4. 创建自己的 Skills 并提交到 Git（Create your own skills and commit them to git）

只要每天要做超过一次的事，就把它做成 skill 或 slash command，并提交到 git 以便跨项目复用。

团队建议：
- 如果某件事每天做超过一次，就做成 skill 或 command
- 做一个 `/techdebt` slash command，每次 session 结束时运行，自动发现并消灭重复代码
- 做一个同步 7 天 Slack、GDrive、Asana、GitHub 的命令，一键生成完整上下文
- 构建 analytics-engineer 风格的 agent：自动写 dbt models、review 代码、在 dev 环境测试变更

更多信息：https://code.claude.com/docs/skills

## 5. 让 Claude 自动修复大部分 Bug（Claude fixes most bugs by itself）

开启 Slack MCP，把 Slack bug 线程直接粘贴给 Claude，然后说 **“fix.”** —— 零上下文切换。  

或者直接说 **“Go fix the failing CI tests.”**，不要 micromanage。  

把 docker logs 指向 Claude 来排查分布式系统，它在这方面意外地强大。

## 6. 提升你的 Prompt 水平（Level up your prompting）

a. 挑战 Claude：“Grill me on these changes and don’t make a PR until I pass your test.” 让 Claude 做你的 reviewer。  
或者说 “Prove to me this works”，让 Claude 对比 main 分支和 feature 分支的行为差异。

b. 修复效果一般时说：“Knowing everything you know now, scrap this and implement the elegant solution.”

c. 提前写详细的 spec，减少歧义后再交给 Claude。越具体越好。

## 7. 终端 & 环境设置（Terminal & Environment Setup）

团队最爱 **Ghostty**（同步渲染、24-bit 色、完美 Unicode 支持）。  

使用 `/statusline` 自定义状态栏，始终显示上下文用量和当前 git branch。  
很多人还会给 terminal tab 配色并命名，有时用 tmux（每个任务/ worktree 一个 tab）。  

**强烈推荐语音输入**（macOS 按 fn 两次）：说话速度是打字的 3 倍，prompt 也会更详细。

## 8. 使用 Subagents（Use subagents）

a. 在任何请求后追加 **“use subagents”**，让 Claude 投入更多算力。  

b. 把单个任务卸载给 subagents，保持主 agent 的上下文干净专注。  

c. 把权限请求路由给 Opus 4.5，通过 hook 让它扫描攻击并自动批准安全的请求。

## 9. 用 Claude 做数据 & 分析（Use Claude for data & analytics）

让 Claude Code 调用 `bq` CLI 实时拉取和分析指标。团队已经在 codebase 里内置了 BigQuery skill，所有人都直接在 Claude Code 里跑分析查询。  

我个人已经 6 个多月没写过一行 SQL 了。  

这个方法适用于任何有 CLI、MCP 或 API 的数据库。

## 10. 用 Claude 学习（Learning with Claude）

a. 在 `/config` 中把 Output Style 设为 **“Explanatory”** 或 **“Learning”**，让 Claude 解释每次变更的 *why*。

b. 让 Claude 生成 HTML 演示文稿来解释不熟悉的代码 —— 它做的幻灯片意外地好看！

c. 要求 Claude 用 ASCII 图表绘制新协议和代码库，帮助你理解结构。

d. 建立 spaced-repetition learning skill：你先解释自己的理解，Claude 追问填补知识盲点，并存储结果。

---

**总结建议**  
这些 tips 全部来自 Claude Code 团队真实工作流。  
**核心实践**：多并行、使用 plan mode、持续维护 **CLAUDE.md**、创建可复用的 skills。