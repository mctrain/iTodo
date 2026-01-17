# iTodo

HarmonyOS Next (API 21) calendar-based todo app with theme switching and JSON import/export.

鸿蒙 HarmonyOS Next（API 21）日历待办应用，支持主题切换与 JSON 导入导出。

## Screenshots / 截图

> *运行应用后可在此添加截图*

## Features / 功能特性

### English
- **Calendar View**: Monthly calendar with date selection and task count indicators
- **Multi-theme Support**: 6 beautiful themes (Dream Purple, Cyberpunk, Nature Green, Sunset Orange, Ocean Blue, Minimal White)
- **Local Persistence**: All data stored locally using HarmonyOS Preferences API
- **JSON Import/Export**: Backup and restore your todos via clipboard
- **Dark Mode Support**: Adaptive system color mode
- **Backup & Restore**: Integrated with HarmonyOS system backup

### 中文
- **日历视图**：月历显示，日期选择，任务数量指示器
- **多主题支持**：6 种精美主题（梦幻紫、赛博朋克、自然绿、日落橙、海洋蓝、简约白）
- **本地持久化**：使用 HarmonyOS Preferences API 本地存储数据
- **JSON 导入/导出**：通过剪贴板备份和恢复待办数据
- **深色模式支持**：自适应系统颜色模式
- **备份与恢复**：集成 HarmonyOS 系统备份功能

## Tech Stack / 技术栈

| Category | Technology |
|----------|------------|
| Language | ETS (Extended TypeScript) |
| UI Framework | ArkUI (Declarative) |
| Build System | Hvigor |
| API Version | HarmonyOS Next 6.0.1 (API 21) |
| Storage | Preferences API |
| Testing | Hypium 1.0.24 |

## Project Structure / 项目结构

```
iTodo/
├── AppScope/                    # 应用全局配置
│   ├── app.json5               # 应用配置
│   └── resources/              # 全局资源
├── entry/                       # 主模块
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/   # 应用入口 Ability
│       │   └── pages/          # UI 页面
│       │       └── Index.ets   # 主页面（核心逻辑）
│       ├── resources/          # 资源文件
│       └── module.json5        # 模块配置
├── build-profile.json5          # 构建配置
└── oh-package.json5             # 依赖配置
```

## Data Format / 数据格式

### Export Format / 导出格式
```json
{
  "2024-01-15": [
    {
      "id": "uuid-string",
      "text": "Todo content",
      "completed": false,
      "createdAt": 1705305600000
    }
  ],
  "2024-01-16": [
    {
      "id": "uuid-string",
      "text": "Another todo",
      "completed": true,
      "createdAt": 1705392000000
    }
  ]
}
```

### Import Formats / 导入格式

The app supports two import formats:

**Format 1: Object format (same as export)**
```json
{
  "YYYY-MM-DD": [TodoItem, ...]
}
```

**Format 2: Array format**
```json
[
  {
    "date": "YYYY-MM-DD",
    "items": [TodoItem, ...]
  }
]
```

## Build & Run / 构建运行

### Prerequisites / 前置条件
- DevEco Studio 5.0 or later
- HarmonyOS SDK (API 21)
- A HarmonyOS device or emulator

### Steps / 步骤

1. Clone the repository / 克隆仓库
   ```bash
   git clone <repository-url>
   cd iTodo
   ```

2. Open in DevEco Studio / 在 DevEco Studio 中打开
   - File -> Open -> Select the project folder

3. Sync dependencies / 同步依赖
   - Click "Sync Now" when prompted

4. Run on device/emulator / 在设备或模拟器上运行
   - Select target device
   - Click Run button or press Shift+F10

## Themes / 主题

| Theme | Primary Color | Description |
|-------|---------------|-------------|
| Dream Purple | `#7E57C2` | 梦幻紫 - Elegant purple theme |
| Cyberpunk | `#00F0FF` | 赛博朋克 - Neon cyan futuristic theme |
| Nature Green | `#2E7D32` | 自然绿 - Fresh green nature theme |
| Sunset Orange | `#F97316` | 日落橙 - Warm orange sunset theme |
| Ocean Blue | `#0284C7` | 海洋蓝 - Calm blue ocean theme |
| Minimal White | `#111827` | 简约白 - Clean minimal light theme |

## License / 许可证

This project is for learning and demonstration purposes.

本项目仅供学习和演示使用。

## Contributing / 贡献

Contributions are welcome! Please feel free to submit issues and pull requests.

欢迎贡献代码！请随时提交 Issue 和 Pull Request。
