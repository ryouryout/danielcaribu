# かんたんな起動方法

## 結論

`index.html` を直接ダブルクリックして開く方法では使えません。

理由:

- このツールは `file://` ではなく `http://127.0.0.1` のようなローカルサーバー上で開く必要があります
- WebHID は安全なコンテキストでしか動かず、ローカルファイル直開きでは接続できません

補足:

- GitHub Pages などの `https://` 公開URLでも利用できます
- 公開URLを使う場合も、PC版の Chrome / Edge と USB 接続が必要です

## いちばん簡単な起動方法

Mac では同じフォルダにある `Start.command` をダブルクリックしてください。
Windows では同じフォルダにある `Start.bat` をダブルクリックしてください。

起動すると:

- ローカルサーバーが自動で立ち上がります
- 可能なら Google Chrome または Microsoft Edge で自動オープンします
- 使うURLは `http://127.0.0.1:4173/` などのローカルURLです
- HTTPS証明書の警告は出ません
- 既定ブラウザが Chrome / Edge 以外の場合は、その URL を Chrome / Edge で開いてください

## 共有するとき

他の人へ渡すときは、このフォルダごと ZIP にして共有してください。

相手側の手順:

1. ZIP を展開する
2. Mac は `Start.command`、Windows は `Start.bat` をダブルクリックする
3. Chrome または Edge で開いたページから接続する

## 対応ブラウザ

- Google Chrome 推奨
- Microsoft Edge 推奨
- Safari は WebHID 非対応のため不可

## 終了方法

`Start.command` または `Start.bat` で開いたターミナル画面に戻り、`Ctrl + C` を押してください。

## もし macOS で最初の起動が止められたら

配布方法によっては macOS が初回だけ確認を出すことがあります。
その場合は `Start.command` を右クリックして `開く` を選べば、その後は通常起動できます。

## もし Windows で起動できなければ

`Start.bat` はまず PowerShell でローカルサーバーを起動します。
うまく動かない場合は、PowerShell で次を実行してください。

```powershell
cd C:\path\to\daniel-caliboo-share
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\launch_local.ps1
```

それでも難しければ、Python 3 が入っている環境で次を実行してください。

```powershell
cd C:\path\to\daniel-caliboo-share
py -3 scripts\launch_local.py
```
