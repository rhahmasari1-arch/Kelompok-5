-- =====================================================================
-- TAHAP 1: Eksplorasi JOIN + fungsi agregasi (database: modul 9)
-- Tabel   : pelanggan, pesanan, detail_pesanan (3 tabel, 2 JOIN)
-- Tujuan  : jumlah pesanan dan total belanja per pelanggan
-- Kompleksitas (dari EXPLAIN ANALYZE): 2 inner hash join -> sort ->
--   group aggregate -> sort -> limit, ~ O(D log D), D = baris detail_pesanan
-- Hasil uji: waktu 0,0050 s; actual time EXPLAIN ANALYZE ~ 0,346 ms
-- =====================================================================
SELECT p.id_pelanggan, p.nama_pelanggan,
       COUNT(DISTINCT ps.id_pesanan)  AS jumlah_pesanan,
       SUM(d.jumlah * d.harga_satuan) AS total_belanja
FROM pelanggan p
JOIN pesanan ps       ON ps.id_pelanggan = p.id_pelanggan
JOIN detail_pesanan d ON d.id_pesanan    = ps.id_pesanan
GROUP BY p.id_pelanggan, p.nama_pelanggan
ORDER BY total_belanja DESC
LIMIT 10;

-- Untuk rencana eksekusi, jalankan terpisah dengan EXPLAIN ANALYZE di depan
-- query di atas.
