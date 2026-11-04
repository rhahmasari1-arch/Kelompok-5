-- =====================================================================
-- TAHAP 2: Denormalisasi - atribut turunan pada tabel master pelanggan
-- Jalankan SATU PER SATU (statement 1, lalu statement 2).
-- =====================================================================

-- 1) DDL: tambah kolom turunan
ALTER TABLE pelanggan ADD COLUMN total_belanja DECIMAL(15,2) DEFAULT 0;

-- 2) Isi kolom dengan hasil perhitungan Tahap 1
UPDATE pelanggan p
SET p.total_belanja = COALESCE((
    SELECT SUM(d.jumlah * d.harga_satuan)
    FROM pesanan ps
    JOIN detail_pesanan d ON d.id_pesanan = ps.id_pesanan
    WHERE ps.id_pelanggan = p.id_pelanggan
), 0);

-- Verifikasi (hasil harus sama dengan Tahap 1)
SELECT id_pelanggan, nama_pelanggan, total_belanja FROM pelanggan;
