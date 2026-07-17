# picpac implementation guide

- 每个module阅读对应的csv文件
- 在做ui implementation时请打开对应reference image并严格按照图片执行，尺寸不一定要完全相同，但尽可能按比例缩放以适应各个尺寸的屏幕
- 提到的API请从docs/api.md中找到，并阅读使用方法
- 抽取并复用component.csv中的组建
- 新提取的component可按照现有格式写入component.csv
- 除了component.csv可以write，docs/implementation_guide下的其余文件均只可读，禁止写入