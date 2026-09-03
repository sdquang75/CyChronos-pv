const USER_ID = 1; // 画面のフォーム初期値用。実際にどのユーザーとして扱われるかはIDトークンで決まる

const TOKEN_STORAGE_KEY = "cychronos.idToken";

function getIdToken() {
  return localStorage.getItem(TOKEN_STORAGE_KEY) ?? "";
}

// 走行データ系API(/api/trips, /api/locations)は Firebase の IDトークンが必須。
// この画面から叩けるように、トークンを貼り付けて保存できる欄を各ページの先頭に差し込む。
// トークンはFlutterアプリのデバッグログなどから取得する(有効期限は1時間)
function setupTokenBar() {
  const bar = document.createElement("div");
  bar.className = "token-bar";
  bar.innerHTML = `
    <label for="id-token">Firebase IDトークン</label>
    <input id="id-token" type="password" placeholder="Bearer の後ろの文字列だけを貼り付け" />
    <button type="button" id="id-token-clear">クリア</button>
    <p class="token-note">
      走行データ系APIは本人のデータしか読み書きできません。トークンが無いと 401 が返ります。
    </p>
  `;
  document.body.insertBefore(bar, document.body.firstChild);

  const input = bar.querySelector("#id-token");
  input.value = getIdToken();
  input.addEventListener("input", () => {
    localStorage.setItem(TOKEN_STORAGE_KEY, input.value.trim());
  });
  bar.querySelector("#id-token-clear").addEventListener("click", () => {
    input.value = "";
    localStorage.removeItem(TOKEN_STORAGE_KEY);
  });
}

document.addEventListener("DOMContentLoaded", setupTokenBar);

async function sendRequest(method, url, body) {
  const resultEl = document.getElementById("result");
  resultEl.className = "result";
  resultEl.textContent = "送信中...";

  try {
    const options = { method, headers: {} };

    const token = getIdToken();
    if (token) {
      options.headers["Authorization"] = `Bearer ${token}`;
    }

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
