# 恶魔城：晓月圆舞曲 原生静态重编译版 (Castlevania: Aria of Sorrow Recomp)

本项目是 Game Boy Advance (GBA) 经典游戏 **《恶魔城：晓月圆舞曲》（Castlevania: Aria of Sorrow, USA 版）** 的 Windows x64 原生静态重编译版本，基于 [GBARecomp](https://github.com/mstan/gbarecomp) 框架并集成了现代原生 GUI 启动器 [recomp-ui](https://github.com/mstan/recomp-ui)。

---

## 游戏信息与启动条件

本项目为纯净引擎与静态重编译器，**不包含** 任何受版权保护的商业 ROM 数据或 GBA BIOS 文件。玩家必须自行提供合法提取的游戏 ROM 与 BIOS。

| 项目 | 要求 / 属性 |
| :--- | :--- |
| **游戏版本** | Castlevania: Aria of Sorrow (USA) |
| **游戏编号 (Game Code)** | `A2CE` |
| **ROM 大小** | `8,388,608` 字节 (8 MiB) |
| **ROM SHA-1** | `abd71fe01ebb201bcc133074db1dd8c5253776c7` |
| **BIOS 大小** | `16,384` 字节 (16 KiB) |
| **BIOS SHA-1** | `300c20df6731a33952ded8c436f7f186d25d3492` |
| **存档类型** | 32 KiB SRAM (`SRAM_F_V102`) |

---

## 启动器与界面特性

双击运行 `CastlevaniaAriaOfSorrowRecomp.exe` 即可打开原生 GUI 启动器：

1. **游戏设置 (Game)**：
   - 浏览并选择 ROM 文件及 GBA BIOS 文件。
   - 自动进行精确 SHA-1 哈希与文件大小门禁校验，非匹配版本将明确拦截。
   - 提供直接启动 (Play)、跳过启动器 (Skip Launcher) 及重置设置 (Reset Settings)。
2. **输入设置 (Input)**：
   - 键盘自定义键位与 SDL2 手柄支持。
   - 手柄热插拔与按键实时重映射。
   - 默认键盘键位：
     - 方向移动：方向键 (Up / Down / Left / Right)
     - 攻击：`Z` (B 键)
     - 跳跃：`X` (A 键)
     - 魂技 / 后撤：`A` / `S` (L / R 键)
     - 暂停菜单：`Enter` (Start 键)
     - 地图显示：`Backspace` / `RShift` (Select 键)
3. **视频设置 (Video)**：
   - 1x ~ 6x 整数画面缩放。
   - 窗口化与全屏显示切换。
   - 保持 GBA 原生 240×160 纵横比。
4. **音频设置 (Audio)**：
   - 主音量调节滑块与实时保存。
5. **配置持久化**：
   - 配置保存于程序同级目录的 `config.ini`、`keybinds.ini`、`rom.cfg` 与 `bios.cfg`。
   - 命令行传入 `--launcher` 可随时重新打开 GUI 启动器。
   - 支持 `--rom <path>`、`--bios <path>`、`--save <path>` 直接启动。

---

## 存档兼容说明

- 默认存档路径位于 `saves/aos.sav`。
- 启动器自动向前兼容游戏根目录或同级目录的历史存档（如 `Castlevania - Aria of Sorrow(US)(Konami)(64Mb).sav`、`aos.sav`），绝不会意外覆盖或重置玩家既有进度。
- 显式传入 `--save <path>` 参数具有最高优先级。

---

## 零依赖玩家运行

- 游戏核心采用 Ahead-of-Time (AOT) 静态重编译与 Stage-1 解释器回退机制。
- 普通玩家**无需**安装 Visual Studio、GCC 或其他任何 C++ 开发工具链，解压即玩。

---

## 许可证说明

- 晓月圆舞曲游戏本身版权归 Konami Digital Entertainment Co., Ltd. 所有。
- 本项目重编译框架与启动器遵循 PolyForm Noncommercial 1.0.0 与 MIT License。详细请见 `LICENSE` 与 `THIRD_PARTY_NOTICES.md`。
