// 期限つきのメモリキャッシュ。同じ条件で外部API(課金あり)を何度も呼ばないために使う。
// サーバー再起動で消える割り切り(この規模ならRedis等は不要)

const DEFAULT_TTL_MS = 5 * 60 * 1000; // 保持時間: 5分
const MAX_ENTRIES = 100;              // 溜めすぎ防止。超えたら一番古いものから捨てる

const store = new Map();

// キーに対応する値を返す。無い・期限切れなら null
function get(key) {
  const entry = store.get(key);
  if (!entry) return null;

  // 期限切れは取り出そうとしたタイミングで捨てる
  if (Date.now() > entry.expiresAt) {
    store.delete(key);
    return null;
  }
  return entry.value;
}

// 値を期限つきで保存する
function set(key, value, ttlMs = DEFAULT_TTL_MS) {
  // Mapは挿入順を覚えているので、先頭のキー=一番古いエントリ
  if (store.size >= MAX_ENTRIES) {
    store.delete(store.keys().next().value);
  }
  store.set(key, { value, expiresAt: Date.now() + ttlMs });
}

module.exports = { get, set };
