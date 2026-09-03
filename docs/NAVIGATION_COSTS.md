# 案内機能の費用設計

確認日: 2026-09-03

## 採用した構成

- 地図表示: 既存のGoogle Maps SDK for Android / iOS
- 自転車ルートと曲がり案内: 既存のMapbox Directions API
- 現在地追従・残距離・逸脱判定: 端末内計算
- 読み上げ: Android / iOSの端末標準TTS
- 振動: Flutterの端末標準ハプティクス

Mapbox Navigation SDKは導入していない。料金体系と実装規模を増やさず、現在契約しているDirections APIを必要時だけ呼ぶ。

## 1走行あたりのDirections API呼び出し

- ルートプレビュー: 1回
- 案内開始: プレビュー取得後5分以内かつ開始地点の移動が50m以内なら0回。条件外なら1回
- 往復の復路準備: 1回
- ルート逸脱: 必要時のみ。精度のよいGPSで3回連続逸脱し、前回再検索から60秒以上経過した場合に1回

通常の片道走行は1回、通常の往復走行は2回が目安になる。

## 料金上限の考え方

- Mapbox Directions APIは月100,000リクエストまで無料。超過分は1,000リクエストあたり2米ドルから。
- Google Mapsのモバイル向けMaps SDK SKUは無料使用上限がUnlimited。ただし請求先アカウントとAPIキー設定は必要。
- 端末標準TTSと振動には従量課金がない。

リリース前にMapboxとGoogle Cloudの両方で、請求アラート、日次クォータ、APIキーのAndroid/iOSアプリ制限を設定する。

## 公式資料

- Mapbox pricing: https://www.mapbox.com/pricing
- Mapbox Directions API: https://docs.mapbox.com/api/navigation/directions/
- Google Maps SDK for Android usage and billing: https://developers.google.com/maps/documentation/android-sdk/usage-and-billing
- Google Maps Platform pricing: https://developers.google.com/maps/billing-and-pricing/pricing
