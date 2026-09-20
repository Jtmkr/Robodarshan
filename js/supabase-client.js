// Requires the Supabase JS CDN script tag to be loaded first:
// <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
//
// The CDN script exposes the library itself as the global `window.supabase`
// (with .createClient, .AuthClient, etc.), so our client instance is named
// `supabaseClient` instead -- naming it `supabase` would shadow/collide with
// that library global. Wrapped in an IIFE with `var` (not `const`) so this
// file is also safe to execute more than once on the same page (e.g. a
// dev-tool or extension re-injecting page scripts) without throwing a
// redeclaration SyntaxError.
(function () {
  var SUPABASE_URL = 'https://wcpsrxkgvlgvxlowusty.supabase.co';
  var SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjcHNyeGtndmxndnhsb3d1c3R5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk4Mzk0MDgsImV4cCI6MjEwNTQxNTQwOH0.VONBM4mcUNbL3Bz_7aPxnFlQhIilbusJGSusAKEixJU';

  window.supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
})();
