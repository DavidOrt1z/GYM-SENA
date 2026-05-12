// ⚙️ CONFIGURACIÓN DE SUPABASE - JACEK GYM

const FALLBACK_SUPABASE_URL = 'https://zvcsywnmscnjlxvmtkqb.supabase.co';
const FALLBACK_SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp2Y3N5d25tc2Nuamx4dm10a3FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwODcwNzYsImV4cCI6MjA4MTY2MzA3Nn0.d2n0Drx9aMlOUzBK4gmI7lT4Vw_OAtuAkgJ1T9f56KM';

const isLocalHost = ['localhost', '127.0.0.1'].includes(window.location.hostname);
window.API_BASE = isLocalHost ? 'http://localhost:5500' : window.location.origin;

window.configReady = (async () => {
    try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 2000);
        const res = await fetch(`${window.API_BASE}/api/config`, { signal: controller.signal });
        clearTimeout(timeout);
        if (!res.ok) throw new Error('No se pudo cargar /api/config');
        const { supabaseUrl, supabaseKey } = await res.json();
        if (!supabaseUrl || !supabaseKey) throw new Error('Configuracion incompleta');
        window.SUPABASE_URL = supabaseUrl;
        window.SUPABASE_ANON_KEY = supabaseKey;
        console.log('✅ Config cargada desde servidor Node');
    } catch (error) {
        console.warn('⚠️ Servidor Node no disponible, usando credenciales locales:', error?.message);
        window.SUPABASE_URL = FALLBACK_SUPABASE_URL;
        window.SUPABASE_ANON_KEY = FALLBACK_SUPABASE_ANON_KEY;
        window.API_BASE = 'http://localhost:5500';
        console.log('✅ Config cargada desde fallback local');
    }
})();

// ✅ Uso en otros módulos:
//   await window.configReady;
//   const url = window.SUPABASE_URL;
//   const api = window.API_BASE;  → 'http://localhost:5500'

window.configReady.then(function() {
  if (typeof supabase !== 'undefined') {
    window.supabaseClient = supabase.createClient(
      window.SUPABASE_URL,
      window.SUPABASE_ANON_KEY
    );
  }
});
