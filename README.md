# CtrlP-Grep.vim
CtrlP-Grep.vimはgrep等のファイル内検索の結果をCtrlPによって表示し、選択した行をVimで開く拡張プラグインです。
指定されたディレクトリ内を再帰的に検索することを想定しているため、grepを用いた他の検索等はできない場合があります。

このプラグインはMITライセンスの元で公開されています。LISENCEを確認してください。

## 要件

- Vim 8.0.1630+
- [CtrlP](https://github.com/ctrlpvim/ctrlp.vim)

# 使い方
CtrlP-Grepは次のように利用することができます。
コマンドを実行するとプロンプトが表示されるので、検索パターンを入力してください。

```vim
" 検索対象のディレクトリを指定します。指定しない場合は、カレントディレクトリが対象になります。
CtrlPGrep /path/to/target

" 拡張子を条件として検索することができます。拡張子は複数指定できます。
CtrlPGrep /path/to/target c,cpp

" 拡張子の先頭に '-' を付けると、検索対象から除外されます。
CtrlPGrep /path/to/target -txt,log
```

ファイル内検索には以下のコマンドを利用することができます。
正規表現の形式や実行速度が異なるので、お好みのコマンドを利用してください。
利用するコマンドは `g:ctrlpgrep_cmd` によって指定します。

- grep
- ag (Silver Searcher)
- rg (ripgrep)
- Select-String
- custom （任意のコマンドとオプションを使用することができます）
