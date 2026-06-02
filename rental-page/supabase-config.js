// ============================================================
// Supabase 連線設定
// ⚠️ 注意：此檔案會被瀏覽器讀到，只放 publishable / anon key
// ⚠️ 絕對不要在這裡放 service_role / secret key
// ============================================================

const SUPABASE_URL = 'https://ugpsyluyqtrkqwhouyck.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_kyjJuJ2uTzBKalvQxDjf_A_u25x9YHQ';

// 建立 Supabase Client（依賴 supabase-js CDN，於 HTML 中先引入）
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// 簡單測試：在 console 印出版本訊息
console.log('[Supabase] Client 初始化完成 →', SUPABASE_URL);