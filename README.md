# danielcaribu

PlayStation コントローラーの校正用静的サイトです。GitHub Pages でそのまま配信できるように調整してあります。

公開URL:

- <https://ryouryout.github.io/danielcaribu/>

使い方:

- `index.html` の直接オープンではなく、GitHub Pages の HTTPS URL か `Start.command` / `Start.bat` で起動したローカル URL を使います
- PC / Mac の Chrome または Edge を使います
- コントローラーは USB 接続で利用します

ローカル起動:

- Mac: `Start.command`
- Windows: `Start.bat`
- 詳細: `README_LOCAL_JP.md`

GitHub Pages:

- `.github/workflows/deploy-pages.yml` により、`main` へ push すると Pages にデプロイされます
