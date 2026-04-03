# Flutter WanAndroid 项目文档中心

> 全面的开发指南、架构说明和快速参考

## 📚 文档导航

### 🎯 [开发指南 (DEVELOPMENT_GUIDE.md)](./DEVELOPMENT_GUIDE.md)

**适合人群**: 新加入项目的开发者、需要了解完整开发流程的团队成员

**内容包括**:
- 项目架构概览（5 层架构详解）
- 技术栈说明
- 完整的目录结构
- 核心设计模式（BaseResp、NetworkCall、PaginationNotifier）
- **开发新功能完整流程**（从 API 定义到 UI 实现的 5 步法）
- 网络请求规范（NetworkService 使用方式）
- 状态管理规范（Riverpod Provider 选择）
- 分页加载实现（PaginationNotifier 详解）
- UI 层开发规范
- 本地存储规范（MMKV、SharedPreferences、Sqflite）
- API 文档速查（常用接口端点）
- 常见问题与最佳实践
- 快速检查清单

**阅读时长**: 30-45 分钟  
**推荐场景**: 首次接触项目、开发新功能前复习规范

---

### ⚡ [快速参考卡片 (QUICK_REFERENCE.md)](./QUICK_REFERENCE.md)

**适合人群**: 已熟悉项目但需要快速查阅语法和模板的开发者

**内容包括**:
- 新功能开发 5 步法（精简版）
- NetworkService 快速用法（GET/POST/链式调用/数据提取）
- 本地存储快速用法
- 常用 API 端点速查表
- UI 状态处理模板
- 分页加载底部指示器模板
- 代码检查清单
- PaginationNotifier 核心方法
- 项目目录速查

**阅读时长**: 5-10 分钟  
**推荐场景**: 开发过程中快速查阅语法、复制模板代码

---

### 🏗️ [架构可视化 (ARCHITECTURE_DIAGRAM.md)](./ARCHITECTURE_DIAGRAM.md)

**适合人群**: 需要深入理解项目架构的开发者、技术 Leader、新加入的高级开发

**内容包括**:
- 整体架构图（5 层架构可视化）
- 数据流向图（3 个典型场景：加载列表、下拉刷新、上拉加载更多）
- 核心类关系图（BaseResp、NetworkCall、PaginationNotifier 等）
- 依赖注入流程图
- 模块依赖关系图
- 关键设计模式详解（Repository、Builder、Template Method、Observer）
- 技术栈依赖图
- 性能优化策略（缓存层级、请求优化）

**阅读时长**: 20-30 分钟  
**推荐场景**: 项目架构 Review、技术分享、新人培训

---

## 🚀 快速开始

### 对于新开发者

**第一步**: 阅读 [开发指南](./DEVELOPMENT_GUIDE.md) 了解项目全貌  
**第二步**: 查看 [架构可视化](./ARCHITECTURE_DIAGRAM.md) 理解数据流  
**第三步**: 尝试开发一个简单功能（参考开发指南中的示例）  
**第四步**: 将 [快速参考卡片](./QUICK_REFERENCE.md) 保存为浏览器书签，随时查阅

### 对于有经验的开发者

直接查阅 [快速参考卡片](./QUICK_REFERENCE.md)，遇到问题时参考 [开发指南](./DEVELOPMENT_GUIDE.md) 的相应章节。

---

## 🤖 AI 功能文档

### [AI 对话功能](./AI_CHAT_FEATURE.md)

**内容包括**:
- AI 对话功能架构说明
- 文件结构和核心组件
- 使用方式（配置、触发对话）
- 配置测试功能
- 重构改进总结

**阅读时长**: 10-15 分钟  
**推荐场景**: 了解 AI 功能实现、二次开发 AI 模块

---

## 📖 文档使用建议

### 场景 1: 我要开发一个新的功能模块

1. 打开 [快速参考卡片](./QUICK_REFERENCE.md)
2. 按照"新功能开发 5 步法"依次实现
3. 复制对应的代码模板
4. 参考"代码检查清单"自查

### 场景 2: 我遇到了网络请求相关的问题

1. 查看 [开发指南 - 网络请求规范](./DEVELOPMENT_GUIDE.md#网络请求规范)
2. 查看 [快速参考 - NetworkService 快速用法](./QUICK_REFERENCE.md#-networkservice-快速用法)
3. 参考现有代码：`lib/remote/CgiArticle.dart`

### 场景 3: 我需要实现分页加载

1. 查看 [开发指南 - 分页加载实现](./DEVELOPMENT_GUIDE.md#分页加载实现)
2. 参考 [架构可视化 - 数据流向图（场景 1、3）](./ARCHITECTURE_DIAGRAM.md#场景-1加载文章列表)
3. 复制 [快速参考](./QUICK_REFERENCE.md) 中的 PaginationNotifier 模板
4. 参考现有代码：`lib/providers/article_provider.dart` 和 `lib/pages/article/article_list_page.dart`

### 场景 4: 我不理解项目的架构设计

1. 阅读 [架构可视化 - 整体架构图](./ARCHITECTURE_DIAGRAM.md#整体架构图)
2. 查看 [架构可视化 - 数据流向图](./ARCHITECTURE_DIAGRAM.md#数据流向图)
3. 了解 [架构可视化 - 关键设计模式](./ARCHITECTURE_DIAGRAM.md#关键设计模式)

### 场景 5: 我需要添加本地存储

1. 查看 [开发指南 - 本地存储规范](./DEVELOPMENT_GUIDE.md#本地存储规范)
2. 复制 [快速参考 - 本地存储 (KV)](./QUICK_REFERENCE.md#本地存储-kv) 中的模板
3. 在 `lib/local/KV.dart` 中添加常量和方法

---

## 🎓 学习路径建议

### 初级开发者（0-3 个月 Flutter 经验）

**Week 1-2**: 
- 通读 [开发指南](./DEVELOPMENT_GUIDE.md)
- 理解 5 层架构的职责分离
- 熟悉 Riverpod 基础用法

**Week 3-4**: 
- 跟着"开发新功能完整流程"实现一个简单的列表页面
- 学习 NetworkService 的基础用法
- 理解 AsyncValue 的三种状态（loading/error/data）

**Month 2**: 
- 实现一个带分页的列表功能
- 学习 PaginationNotifier 的使用
- 熟悉本地存储 (MMKV)

**Month 3**: 
- 独立开发完整功能模块
- 阅读 [架构可视化](./ARCHITECTURE_DIAGRAM.md) 理解设计模式
- 能够优化现有代码

### 中级开发者（3-12 个月 Flutter 经验）

**Day 1**: 
- 快速浏览 [开发指南](./DEVELOPMENT_GUIDE.md)
- 重点阅读"核心设计模式"章节

**Day 2-3**: 
- 深入理解 [架构可视化](./ARCHITECTURE_DIAGRAM.md)
- 分析现有代码的实现方式
- 尝试优化一个现有功能

**Ongoing**: 
- 使用 [快速参考卡片](./QUICK_REFERENCE.md) 提高开发效率
- 参与代码 Review，确保团队代码一致性
- 提出架构改进建议

### 高级开发者 / Tech Lead

- 审阅所有文档，提出改进意见
- 使用 [架构可视化](./ARCHITECTURE_DIAGRAM.md) 进行技术分享
- 制定团队编码规范
- 优化 PaginationNotifier、NetworkCall 等基础设施

---

## 🛠️ AI 助手集成

本项目已配置**专属 AI 开发助手 Skill**，位于：
```
.codebuddy/rules/flutter-wanandroid-dev-assistant.mdc
```

### Skill 功能

当你向 AI 助手提出开发需求时，它会：
1. ✅ 严格遵循本项目的 5 层架构
2. ✅ 使用 PaginationNotifier 实现分页列表
3. ✅ 按照规范生成 API 定义、Cgi 层、Provider、UI 层
4. ✅ 生成符合项目风格的代码
5. ✅ 提供代码检查清单

### 使用示例

**你**: "帮我实现一个收藏的项目列表功能，需要支持分页加载"

**AI 助手**（基于 Skill）会自动：
- 在 `Api.dart` 中添加 URL 常量、Req、Resp
- 创建 `CgiCollectProject.dart` 封装业务逻辑
- 创建 `collect_project_provider.dart` 使用 PaginationNotifier
- 创建 `collect_project_page.dart` UI 页面
- 提供完整可运行的代码
- 给出集成建议（如路由配置）

---

## 📊 文档版本

| 文档 | 版本 | 更新日期 | 作者 |
|------|------|----------|------|
| DEVELOPMENT_GUIDE.md | v1.0 | 2026-01-13 | Flutter WanAndroid Team |
| QUICK_REFERENCE.md | v1.0 | 2026-01-13 | Flutter WanAndroid Team |
| ARCHITECTURE_DIAGRAM.md | v1.0 | 2026-01-13 | Flutter WanAndroid Team |
| README.md | v1.0 | 2026-01-13 | Flutter WanAndroid Team |

---

## 🤝 贡献指南

发现文档问题或有改进建议？

1. 在项目中创建 Issue
2. 提交 Pull Request
3. 联系项目维护者

---

## 📞 获取帮助

- **项目文档问题**: 查看本 docs 目录下的相关文档
- **代码问题**: 参考现有代码实现（如 `CgiArticle.dart`、`article_provider.dart`）
- **架构疑问**: 阅读 [架构可视化](./ARCHITECTURE_DIAGRAM.md)
- **开发阻塞**: 使用 AI 开发助手 Skill

---

## 🎉 总结

本文档体系为 Flutter WanAndroid 项目提供了：

✅ **全面的开发指南**：从入门到精通的完整路径  
✅ **快速的参考卡片**：开发过程中随时查阅  
✅ **清晰的架构说明**：深入理解设计理念  
✅ **AI 助手集成**：自动化代码生成符合规范  

遵循本文档，你可以：
- 🚀 快速上手项目开发
- 📈 持续提升代码质量
- 🤝 保持团队代码一致性
- 💡 理解并改进项目架构

---

**Happy Coding! 🎊**
