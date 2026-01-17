# iTodo

HarmonyOS Next (API 21) calendar-based todo app with theme switching and JSON import/export.

鸿蒙 HarmonyOS Next（API 21）日历待办应用，支持主题切换与 JSON 导入导出。

## Features / 功能特性
- Calendar view with date selection
- Multi-theme support (6 themes)
- Local persistence
- JSON import/export

- 日历视图与日期选择
- 6 种主题切换
- 本地数据持久化
- JSON 导入/导出备份

## Data Format / 数据格式
```json
{
  "YYYY-MM-DD": [
    { "id": "string", "text": "string", "completed": false, "createdAt": 0 }
  ]
}
```

## Build & Run / 构建运行
Open the project in DevEco Studio and run on a device or emulator.

使用 DevEco Studio 打开工程，选择设备或模拟器运行。
