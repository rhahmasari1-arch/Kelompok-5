-- =====================================================================
-- TAHAP 3: Pembuktian - baca kolom denormalisasi
-- Tanpa JOIN dan tanpa fungsi agregasi.
-- Hasil uji: waktu 0,0027 s; actual time EXPLAIN ANALYZE ~ 0,102 ms
-- Rencana: Table scan on pelanggan -> Sort -> Limit (1 tabel)
-- =====================================================================
SELECT id_pelanggan, nama_pelanggan, total_belanja
FROM pelanggan
ORDER BY total_belanja DESC
LIMIT 10;

-- Untuk rencana eksekusi, jalankan terpisah dengan EXPLAIN ANALYZE di depan
-- query di atas.
