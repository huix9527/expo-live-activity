# Live Activity - App Groups 快速参考

## 在 Widget 中读取共享数据

### 导入

```swift
import Foundation
// 使用 AppGroupsHelper (见: ios-files/AppGroupsHelper.swift)
```

### 读取 JSON 数据

```swift
// 读取宠物数据
let petData = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self)

// 读取配置
let config = AppGroupsHelper.readJSON("activity-config", as: SharedActivityConfig.self)

// 自定义类型
let customData = AppGroupsHelper.readJSON("my-data", as: MyType.self)
```

### 加载图片

```swift
// 直接加载
if let image = AppGroupsHelper.loadImage("pet-avatar.jpg") {
    Image(uiImage: image)
}

// 获取路径
if let path = AppGroupsHelper.getImagePath("pet-avatar.jpg") {
    let image = UIImage(contentsOfFile: path)
}

// 检查存在性
if AppGroupsHelper.fileExists("images/pet-avatar.jpg") {
    // 文件存在
}
```

### 调试

```swift
// 打印所有文件
AppGroupsHelper.debugPrintAllFiles()

// 读取原始文本
if let content = AppGroupsHelper.readFile("data/current-pet.json") {
    print(content)
}
```

## 数据结构

```swift
// 宠物数据
struct SharedPetData: Codable {
    let id: String
    let name: String
    let breed: String?
    let avatarPath: String?      // 绝对路径
    let lastUpdated: String      // ISO8601 格式
}

// 配置
struct SharedActivityConfig: Codable {
    let showAvatar: Bool
    let updateInterval: Int      // 秒
    let theme: String           // "light"/"dark"/"auto"
}
```

## 容器路径

```
group.com.epbs.fun.patpet/
├── data/current-pet.json
├── data/activity-config.json
├── images/pet-avatar.jpg
└── cache/...
```

## 常见模式

### 模式 1: 加载数据并显示

```swift
@State private var petData: SharedPetData?

var body: some View {
    VStack {
        if let pet = petData {
            Text(pet.name)
                .font(.headline)
            if let image = AppGroupsHelper.loadImage("pet-avatar.jpg") {
                Image(uiImage: image)
            }
        }
    }
    .onAppear {
        petData = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self)
    }
}
```

### 模式 2: 带错误处理

```swift
private func loadData() {
    guard AppGroupsHelper.fileExists("data/current-pet.json") else {
        print("❌ 文件不存在")
        return
    }

    guard let data = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self) else {
        print("❌ 解析失败")
        return
    }

    petData = data
}
```

### 模式 3: 安全加载

```swift
func loadPetImageSafely() -> UIImage? {
    // 尝试主路径
    if let image = AppGroupsHelper.loadImage("pet-avatar.jpg") {
        return image
    }

    // 尝试备用路径
    if let image = AppGroupsHelper.loadImage("current-pet-avatar.jpg") {
        return image
    }

    // 返回默认图片
    return UIImage(systemName: "pawprint.fill")
}
```

## 故障排除

| 问题 | 解决方案 |
|------|--------|
| 无法读取数据 | 检查 App Group ID 一致性，运行 `debugPrintAllFiles()` |
| JSON 解析失败 | 验证 Codable 模型，打印原始 JSON |
| 图片无法加载 | 使用 `getImagePath()` 验证路径，检查文件是否存在 |
| 数据为空 | 确认主应用已写入数据，检查文件权限 |

## 文件位置

- **App Groups 辅助类**: [AppGroupsHelper.swift](ios-files/AppGroupsHelper.swift)
- **完整示例**: [AppGroupsUsageExample.swift](ios-files/AppGroupsUsageExample.swift)
- **详细文档**: [README_APP_GROUPS.md](README_APP_GROUPS.md)
- **主应用实现**: [appgroup-storage 模块](../app/modules/appgroup-storage/)

## 相关代码

### 主应用中写入数据

```typescript
// app/modules/appgroup-storage/src/AppgroupStorageHelper.ts
await AppgroupStorageHelper.writeJSON('current-pet', petData);
await AppgroupStorageHelper.shareImage(imageUri, 'pet-avatar.jpg');
```

### Widget 中读取数据

```swift
// expo-live-activity/ios-files/AppGroupsHelper.swift
let pet = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self)
let image = AppGroupsHelper.loadImage("pet-avatar.jpg")
```

## 完整工作流程

1. **主应用**: 用户选择宠物头像
   ```typescript
   const path = await AppgroupStorageHelper.shareImage(uri, 'pet-avatar.jpg');
   ```

2. **主应用**: 保存宠物数据
   ```typescript
   await AppgroupStorageHelper.writeJSON('current-pet', petData);
   ```

3. **Live Activity**: 启动时读取数据
   ```swift
   let pet = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self)
   let image = AppGroupsHelper.loadImage("pet-avatar.jpg")
   ```

4. **Live Activity**: 显示宠物信息
   ```swift
   VStack {
       Image(uiImage: image)
       Text(pet.name)
   }
   ```
