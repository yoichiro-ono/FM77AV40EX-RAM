# FM77AV40EX-RAM

## FM77AV40EX/SX用の512KRAMカード

### schematic.pdf：回路図

### MEMTESTB.BAS：簡易チェック

### MEMTESTM.BAS：少し詳細チェック(マシン語）

### MEMTEST.ASM：詳細テスト

- 全領域に以下のパターンを纏めて書き込み＆読み出しテスト
<br/>0x00,0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80,0xFF,0xFE,0xFD,0xFB,0xF7,0xEF,0xDF,0xBF,0x7F

- 全領域に昇順に$0x5書き込み、0xAA書き込み、読み出しテスト

- 全領域に昇順に0xAA書き込み、0x55書き込み、読み出しテスト

- 全領域に0xAAを纏めて書き込み

- 全領域に昇順に0xAA読み出しテスト、0x55書き込み

- 全領域に降順に0x55読み出しテスト、0xAA書き込み

- 拡張メモリを割り当てた領域(0x5000-0x5FFF)にプログラムを
書き込みし実行(全領域で実施)

- 拡張メモリの物理アドレスがALL0とALL1のバイト(0x40000,0xBFFFF)に
交互に0xFFを書き込みしデータが化けないことのテスト



## メモリテストのアルゴリズムは以下のサイト・PDFを参考にしました。


**https://github.com/anachrocomputer/RC2014tester**


**https://ballyalley.com/ml/ml_source/RAM%20Test%20[From%20Z80%20Assembly%20Language%20Subroutines].pdf**


**http://www.ganssle.com/articles/ramtest.htm**



