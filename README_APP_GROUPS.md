# Live Activity - App Groups 数据读取指南

如何在 Live Activity Widget 中读取主应用通过 App Groups 共享的数据。

## 概述

Live Activity Widget 与主应用共享同一个 App Groups 容器：
- **Group ID**: `group.com.epbs.fun.patpet`
- **数据位置**:
  - JSON 数据: `data/` 目录
  - 图片资源: `images/` 目录
  - 缓存文件: `cache/` 目录

## 快速开始

### 1. 导入辅助类

```swift
import Foundation

// AppGroupsHelper 提供了便捷的数据读取接口
// 参见: AppGroupsHelper.swift
```

### 2. 读取 JSON 数据

```swift
// 读取宠物数据
if let petData = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self) {
    print("宠物名称: \(petData.name)")
    print("品种: \(petData.breed ?? "未知")")
}
```

### 3. 加载图片

```swift
// 方法 1: 直接加载图片
if let petImage = AppGroupsHelper.loadImage("pet-avatar.jpg") {
    Image(uiImage: petImage)
        .resizable()
        .scaledToFit()
}

// 方法 2: 获取图片路径，自己加载
if let imagePath = AppGroupsHelper.getImagePath("pet-avatar.jpg") {
    let image = UIImage(contentsOfFile: imagePath)
}
```

### 4. 检查文件存在性

```swift
if AppGroupsHelper.fileExists("data/current-pet.json") {
    print("宠物数据文件存在")
}
```

## 数据结构

### SharedPetData

从主应用共享的宠物数据：

```swift
struct SharedPetData: Codable {
    let id: String              // 唯一标识符
    let name: String            // 宠物名称
    let breed: String?          // 品种
    let avatarPath: String?     // 头像文件路径
    let lastUpdated: String     // 最后更新时间 (ISO8601 格式)
}
```

**主应用中的创建方式**:

```typescript
// app/screens/Develop/AppgroupStorageTest.js
const petData: SharedPetData = {
  id: '123',
  name: 'Buddy',
  breed: 'Golden Retriever',
  avatarPath: '/path/to/container/images/pet-avatar.jpg',
  lastUpdated: new Date().toISOString(),
};

await AppgroupStorageHelper.writeJSON('current-pet', petData);
```

### SharedActivityConfig

活动配置：

```swift
struct SharedActivityConfig: Codable {
    let showAvatar: Bool        // 是否显示头像
    let updateInterval: Int     // 更新间隔（秒）
    let theme: String           // 主题: "light", "dark", "auto"
}
```

## 完整示例

### 示例 1: 在 Widget 中显示宠物数据

```swift
struct PetActivityView: View {
    let contentState: LiveActivityAttributes.ContentState
    let attributes: LiveActivityAttributes

    @State private var petData: SharedPetData?
    @State private var petImage: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            // 宠物头像
            if let image = petImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Text("🐶")
                    .font(.system(size: 32))
            }

            // 宠物信息
            if let pet = petData {
                VStack(alignment: .leading) {
                    Text(pet.name)
                        .font(.headline)
                    if let breed = pet.breed {
                        Text(breed)
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }

            // 活动内容
            Text(contentState.title)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding()
        .onAppear {
            loadSharedData()
        }
    }

    private func loadSharedData() {
        // 读取宠物数据
        petData = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self)

        // 加载宠物头像
        if let imagePath = petData?.avatarPath,
           let image = UIImage(contentsOfFile: imagePath) {
            petImage = image
        }
    }
}
```

### 示例 2: 带错误处理的数据加载

```swift
func loadPetDataSafely() -> (SharedPetData, UIImage)? {
    // 1. 验证数据有效性
    guard AppGroupsHelper.fileExists("data/current-pet.json") else {
        print("❌ 宠物数据文件不存在")
        return nil
    }

    // 2. 读取 JSON 数据
    guard let petData = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self) else {
        print("❌ 无法读取宠物数据")
        return nil
    }

    // 3. 验证数据完整性
    guard !petData.id.isEmpty && !petData.name.isEmpty else {
        print("❌ 宠物数据不完整")
        return nil
    }

    // 4. 尝试加载图片
    guard let image = AppGroupsHelper.loadImage("pet-avatar.jpg") else {
        print("⚠️ 无法加载宠物头像")
        return (petData, UIImage())  // 返回数据，图片为空
    }

    return (petData, image)
}
```

### 示例 3: 使用配置信息

```swift
func configureWidget() {
    // 读取配置
    let config = SafeDataAccessExample.loadConfiguration()

    // 根据配置调整 UI
    if config.showAvatar {
        // 显示头像部分
    }

    // 根据主题调整颜色
    let textColor: Color = config.theme == "dark" ? .white : .black

    // 设置更新间隔
    let updateInterval = TimeInterval(config.updateInterval)
}
```

## 调试

### 打印所有共享文件

在开发中调试时，查看容器中的所有文件：

```swift
AppGroupsHelper.debugPrintAllFiles()
```

输出示例：
```
📦 Shared Container URL: /var/mobile/Containers/Shared/AppGroup/group.com.epbs.fun.patpet
📁 data/
  📄 current-pet.json
  📄 activity-config.json
📁 images/
  📄 pet-avatar.jpg
📁 cache/
  📄 temp-data.txt
```

### 调试视图

可以在 Widget 预览中使用调试视图：

```swift
#if DEBUG
struct WidgetPreview: PreviewProvider {
    static var previews: some View {
        DebugAppGroupsView()
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
#endif
```

## 常见问题

### Q: 无法读取共享数据

**A**: 检查以下几点：

1. 两个 target 的 App Group ID 是否相同？
   - 主应用: `app/ios/Furever/Furever.entitlements`
   - Widget: `app/ios/LiveActivity/LiveActivity.entitlements`

2. 主应用是否已写入数据？
   ```swift
   await AppgroupStorageHelper.writeJSON('current-pet', petData);
   ```

3. 使用 `debugPrintAllFiles()` 验证文件确实存在

4. 检查文件路径是否正确（注意 `data/` 前缀）

### Q: 图片无法加载

**A**:

1. 验证图片文件确实存在在 `images/` 目录
2. 检查图片路径是否正确（绝对路径）
3. 检查图片格式是否支持（JPEG, PNG）
4. 使用 `getImagePath()` 确认路径

### Q: JSON 解析失败

**A**:

1. 确保 JSON 数据格式正确
2. 验证 Codable 模型与实际数据结构匹配
3. 检查编码格式（应为 UTF-8）
4. 使用 `#if DEBUG` 输出原始 JSON 内容用于调试

```swift
if let content = AppGroupsHelper.readFile("data/current-pet.json") {
    print("Raw JSON: \(content)")
}
```

## 最佳实践

### 1. 缓存数据

避免每次都读取文件，使用 @State 缓存：

```swift
@State private var petData: SharedPetData?
@State private var cachedAt: Date = Date()

var shouldRefresh: Bool {
    Date().timeIntervalSince(cachedAt) > 60  // 1分钟后刷新
}
```

### 2. 处理数据更新

主应用数据更新时，Widget 会自动刷新，但应处理不存在的情况：

```swift
private func loadWithFallback() {
    if let data = AppGroupsHelper.readJSON("current-pet", as: SharedPetData.self) {
        petData = data
    } else {
        // 使用默认数据或空状态
        petData = nil
    }
}
```

### 3. 错误日志

使用 print 输出调试信息，在生产环境中会被过滤：

```swift
#if DEBUG
    print("📝 Loading pet data...")
#endif
```

### 4. 验证数据新鲜度

检查数据是否过期：

```swift
func isDataFresh() -> Bool {
    guard let petData = petData else { return false }

    let dateFormatter = ISO8601DateFormatter()
    guard let lastUpdated = dateFormatter.date(from: petData.lastUpdated) else {
        return false
    }

    let age = Date().timeIntervalSince(lastUpdated)
    return age < 3600  // 小于 1 小时
}
```

## 文件结构

```
共享容器 (group.com.epbs.fun.patpet)
├── data/
│   ├── current-pet.json          # 当前宠物数据
│   └── activity-config.json      # 活动配置
├── images/
│   ├── pet-avatar.jpg            # 宠物头像
│   └── pet-photo-1.jpg           # 其他图片
└── cache/
    └── temp-data.json            # 临时缓存
```

## 相关文件

- [AppGroupsHelper.swift](AppGroupsHelper.swift) - 数据读取辅助类
- [AppGroupsUsageExample.swift](AppGroupsUsageExample.swift) - 完整使用示例
- [主应用 App Groups 实现](../../app/modules/appgroup-storage/) - 数据写入端

## 参考资源

- [iOS App Groups 官方文档](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)
- [Live Activities 官方文档](https://developer.apple.com/documentation/activitykit)
- [WidgetKit 官方文档](https://developer.apple.com/documentation/widgetkit)
