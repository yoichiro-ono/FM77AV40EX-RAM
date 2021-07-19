"# FM77AV40EX-RAM" 

FM77AV40EX/SX用の512KRAMカード

schematic.pdf：回路図

MEMTESTB.BAS：簡易チェック

MEMTESTM.BAS：少し詳細チェック(マシン語）

MEMTEST.ASM：詳細テスト

・全領域に以下のパターンを纏めて書き込み＆読み出しテスト
　$00,$01,$02,$04,$08,$10,$20,$40,$80
　$FF,$FE,$FD,$FB,$F7,$EF,$DF,$BF,$7F

・全領域に昇順に$55書き込み、$AA書き込み、読み出しテスト

・全領域に昇順に$AA書き込み、$55書き込み、読み出しテスト

・全領域に$AAを纏めて書き込み

・全領域に昇順に$AA読み出しテスト、$55書き込み

・全領域に降順に$55読み出しテスト、$AA書き込み

・拡張メモリを割り当てた領域($5000-$5FFF)にプログラムを
　書き込みし実行(全領域で実施)

・拡張メモリの物理アドレスがALL0とALL1のバイト($40000,$BFFFF)に
　交互に$FFを書き込みしデータが化けないことのテスト



メモリテストのアルゴリズムは以下のサイト・PDFを参考にしました。


https://github.com/anachrocomputer/RC2014tester


https://ballyalley.com/ml/ml_source/RAM%20Test%20[From%20Z80%20Assembly%20Language%20Subroutines].pdf


http://www.ganssle.com/articles/ramtest.htm




