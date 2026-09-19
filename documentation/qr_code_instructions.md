# 生成二维码指南

## 🎯 为交互式地图生成二维码

### 方法一：在线QR码生成器 (推荐)

#### 步骤：
1. 访问在线QR码生成器：
   - https://qr-code-generator.com/
   - https://www.qr-code-generator.com/
   - https://qr.io/

2. 输入链接内容：
   ```
   file:///path/to/london_chinatown_final_report/interactive_map.html
   ```

3. 生成并下载PNG格式的二维码

4. 保存为 `interactive_map_qr_code.png`

### 方法二：使用Google Charts API

#### 直接访问链接：
```
https://chart.googleapis.com/chart?chs=300x300&cht=qr&chl=file:///path/to/london_chinatown_final_report/interactive_map.html
```

#### 步骤：
1. 复制上述链接到浏览器
2. 右键保存图片
3. 重命名为 `interactive_map_qr_code.png`

### 方法三：使用Python生成 (如果有Python环境)

#### 代码：
```python
import qrcode

# 创建二维码
qr = qrcode.QRCode(
    version=1,
    error_correction=qrcode.constants.ERROR_CORRECT_L,
    box_size=10,
    border=4,
)

# 添加数据
qr.add_data('file:///path/to/london_chinatown_final_report/interactive_map.html')
qr.make(fit=True)

# 创建图片
img = qr.make_image(fill_color="black", back_color="white")

# 保存
img.save("interactive_map_qr_code.png")
```

### 方法四：使用在线工具生成

#### 推荐工具：
1. **QR Code Generator**: https://www.qr-code-generator.com/
2. **QR.io**: https://qr.io/
3. **QR Code Monkey**: https://www.qrcode-monkey.com/

#### 输入内容：
```
file:///path/to/london_chinatown_final_report/interactive_map.html
```

## 📱 二维码使用方法

### 在PPT中使用：
1. 插入 → 图片 → 此设备
2. 选择二维码图片
3. 调整大小和位置
4. 添加说明文字："扫码查看交互式地图"

### 演示时：
1. 观众用手机扫描二维码
2. 自动打开交互式地图
3. 可以缩放、点击查看详细信息

## 🔧 技术说明

### 本地文件路径：
- 二维码链接到本地HTML文件
- 需要确保文件路径正确
- 适用于离线演示

### 在线版本：
如果需要在线版本，可以：
1. 上传HTML文件到GitHub Pages
2. 获取在线链接
3. 重新生成二维码

## 📋 文件清单

确保以下文件存在：
- `interactive_map.html` - 交互式地图
- `interactive_map_files/` - 地图支持文件
- `interactive_map_qr_code.png` - 二维码图片

## 🎯 最佳实践

### 演示准备：
1. 提前测试二维码扫描
2. 确保HTML文件可正常打开
3. 准备备用方案（如直接打开HTML）

### 文件管理：
1. 将所有文件放在同一文件夹
2. 使用绝对路径生成二维码
3. 压缩整个文件夹便于分享

---

**提示**: 推荐使用方法一（在线QR码生成器），简单快捷且质量好。
