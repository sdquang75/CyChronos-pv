const USER_ID = 1; // ユーザーIDは1で固定

async function sendRequest(method, url, body) {
  const resultEl = document.getElementById("result");
  resultEl.className = "result";
  resultEl.textContent = "送信中...";

  try {
    const options = { method, headers: {} };
    if (body !== undefined) {
      options.headers["Content-Type"] = "application/json";
      options.body = JSON.stringify(body);
    }

    const res = await fetch(url, options);
    const text = await res.text();

    let pretty = "(レスポンスボディなし)";
    if (text) {
      try {
        pretty = JSON.stringify(JSON.parse(text), null, 2);
      } catch {
        pretty = text;
      }
    }

    resultEl.textContent = `HTTP ${res.status} ${res.statusText}\n\n${pretty}`;
    resultEl.className = res.ok ? "result ok" : "result error";
  } catch (err) {
    resultEl.textContent = "リクエスト失敗: " + err.message;
    resultEl.className = "result error";
  }
}
