-- =====================================================================
-- PRAKTIKUM MODUL 10: DBMS DAN APLIKASI BASIS DATA
-- Kasus     : Pasar Tradisional (skema dbpasar_tradisional, 9 tabel)
-- DBMS      : MySQL Community Server 8.4.3 | Pengelola: phpMyAdmin
-- Kelompok  : <isi nama anggota, kelas>
--
-- Database baru: praktikum_modul10_pasar (tidak menyentuh database lain).
-- Jalankan PER BAGIAN (satu kali klik Go), lalu screenshot hasilnya.
-- Bagian bertanda "SENGAJA GAGAL" dijalankan satu per satu.
--
-- Urutan tabel (induk dulu, anak kemudian):
--   pasar -> kios -> barang -> stok
--   pelaku_pasar -> pedagang, pembeli -> transaksi -> detail_transaksi
-- =====================================================================


-- =====================================================================
-- TAHAP 1 - EKSPLORASI DBMS DAN ARSITEKTUR
-- (jalankan satu per satu, screenshot masing-masing)
-- =====================================================================
SELECT VERSION();

SELECT @@version_comment;

SHOW ENGINES;

SHOW DATABASES;


-- =====================================================================
-- TAHAP 2 - IMPLEMENTASI BASIS DATA
-- =====================================================================

-- 2.1 Membuat database
CREATE DATABASE praktikum_modul10_pasar;

USE praktikum_modul10_pasar;

-- 2.2 Tabel pasar
CREATE TABLE pasar (
    id_pasar INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_pasar VARCHAR(100) NOT NULL UNIQUE,
    alamat VARCHAR(200),
    lokasi VARCHAR(100)
) ENGINE=InnoDB;

-- 2.3 Tabel kios
CREATE TABLE kios (
    id_kios INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_pasar INT UNSIGNED NOT NULL,
    nama_kios VARCHAR(100) NOT NULL,
    ukuran VARCHAR(50),

    CONSTRAINT fk_kios_pasar
    FOREIGN KEY (id_pasar)
    REFERENCES pasar(id_pasar)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 2.4 Tabel barang
CREATE TABLE barang (
    id_barang INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_kios INT UNSIGNED NOT NULL,
    nama_barang VARCHAR(100) NOT NULL,
    kategori VARCHAR(100),
    harga_satuan DECIMAL(12,2) NOT NULL,
    satuan VARCHAR(30),
    stok_min INT UNSIGNED NOT NULL DEFAULT 0,

    CONSTRAINT fk_barang_kios
    FOREIGN KEY (id_kios)
    REFERENCES kios(id_kios)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,

    CONSTRAINT chk_harga_barang
    CHECK (harga_satuan >= 0)
) ENGINE=InnoDB;

-- 2.5 Tabel stok
CREATE TABLE stok (
    id_stok INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_barang INT UNSIGNED NOT NULL,
    tanggal DATE NOT NULL,
    stok_masuk INT UNSIGNED NOT NULL DEFAULT 0,
    stok_keluar INT UNSIGNED NOT NULL DEFAULT 0,
    stok_akhir INT UNSIGNED NOT NULL DEFAULT 0,

    UNIQUE KEY uq_stok_barang_tanggal (id_barang, tanggal),

    CONSTRAINT fk_stok_barang
    FOREIGN KEY (id_barang)
    REFERENCES barang(id_barang)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 2.6 Tabel pelaku_pasar (induk dari pedagang dan pembeli)
CREATE TABLE pelaku_pasar (
    id_pelaku INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(100) NOT NULL,
    alamat VARCHAR(200),
    no_hp VARCHAR(20)
) ENGINE=InnoDB;

-- 2.7 Tabel pedagang
CREATE TABLE pedagang (
    id_pelaku INT UNSIGNED PRIMARY KEY,
    id_kios INT UNSIGNED NOT NULL,
    kategori_usaha VARCHAR(100),

    CONSTRAINT fk_pedagang_pelaku
    FOREIGN KEY (id_pelaku)
    REFERENCES pelaku_pasar(id_pelaku)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

    CONSTRAINT fk_pedagang_kios
    FOREIGN KEY (id_kios)
    REFERENCES kios(id_kios)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 2.8 Tabel pembeli
CREATE TABLE pembeli (
    id_pelaku INT UNSIGNED PRIMARY KEY,

    CONSTRAINT fk_pembeli_pelaku
    FOREIGN KEY (id_pelaku)
    REFERENCES pelaku_pasar(id_pelaku)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- 2.9 Tabel transaksi
CREATE TABLE transaksi (
    id_transaksi INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tanggal DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metode_pembayaran VARCHAR(50),
    total_bayar DECIMAL(14,2) NOT NULL DEFAULT 0,
    id_pembeli INT UNSIGNED NOT NULL,
    id_pedagang INT UNSIGNED NOT NULL,

    CONSTRAINT fk_transaksi_pembeli
    FOREIGN KEY (id_pembeli)
    REFERENCES pembeli(id_pelaku)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,

    CONSTRAINT fk_transaksi_pedagang
    FOREIGN KEY (id_pedagang)
    REFERENCES pedagang(id_pelaku)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,

    CONSTRAINT chk_total_bayar
    CHECK (total_bayar >= 0)
) ENGINE=InnoDB;

-- 2.10 Tabel detail_transaksi
CREATE TABLE detail_transaksi (
    id_detail INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_transaksi INT UNSIGNED NOT NULL,
    id_barang INT UNSIGNED NOT NULL,
    jumlah INT UNSIGNED NOT NULL,
    harga_satuan DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(14,2) NOT NULL,

    CONSTRAINT fk_detail_transaksi
    FOREIGN KEY (id_transaksi)
    REFERENCES transaksi(id_transaksi)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,

    CONSTRAINT fk_detail_barang
    FOREIGN KEY (id_barang)
    REFERENCES barang(id_barang)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,

    CONSTRAINT chk_jumlah_detail
    CHECK (jumlah > 0),

    CONSTRAINT chk_harga_detail
    CHECK (harga_satuan >= 0),

    CONSTRAINT chk_subtotal_detail
    CHECK (subtotal >= 0)
) ENGINE=InnoDB;

-- 2.11 Memeriksa relasi tabel (jalankan satu per satu)
SHOW TABLES;

SHOW CREATE TABLE kios;

SHOW CREATE TABLE barang;

SHOW CREATE TABLE pedagang;

SHOW CREATE TABLE transaksi;

SHOW CREATE TABLE detail_transaksi;

-- Daftar seluruh foreign key
SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME
FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'praktikum_modul10_pasar'
ORDER BY TABLE_NAME;

-- Mahasiswa mengidentifikasi: primary key, foreign key, relasi one-to-many,
-- relasi antarentitas, dan constraint yang diterapkan.

-- 2.12 Mengisi data awal (induk dulu, anak kemudian)
INSERT INTO pasar
    (id_pasar, nama_pasar, alamat, lokasi)
VALUES
    (1, 'Pasar Sleko', 'Jl. Pasar Sleko No. 1', 'Madiun'),
    (2, 'Pasar Besar', 'Jl. Pasar Besar No. 5', 'Madiun');

INSERT INTO kios
    (id_kios, id_pasar, nama_kios, ukuran)
VALUES
    (1, 1, 'Kios Sayur Segar', '3x3 m'),
    (2, 1, 'Kios Beras Makmur', '4x3 m'),
    (3, 2, 'Kios Bumbu Jaya', '2x3 m');

INSERT INTO barang
    (id_barang, id_kios, nama_barang, kategori, harga_satuan, satuan, stok_min)
VALUES
    (1, 1, 'Bayam', 'Sayuran', 3000, 'ikat', 20),
    (2, 1, 'Wortel', 'Sayuran', 12000, 'kg', 15),
    (3, 2, 'Beras Premium', 'Sembako', 14000, 'kg', 50),
    (4, 3, 'Bawang Merah', 'Bumbu', 35000, 'kg', 10);

INSERT INTO stok
    (id_stok, id_barang, tanggal, stok_masuk, stok_keluar, stok_akhir)
VALUES
    (1, 1, '2026-11-09', 50, 20, 30),
    (2, 1, '2026-11-10', 40, 45, 25),
    (3, 2, '2026-11-10', 30, 22, 8),
    (4, 3, '2026-11-10', 100, 30, 70),
    (5, 4, '2026-11-10', 20, 12, 8);

INSERT INTO pelaku_pasar
    (id_pelaku, nama, alamat, no_hp)
VALUES
    (1, 'Pak Joko', 'Madiun', '081234567890'),
    (2, 'Bu Sari', 'Madiun', '081298765432'),
    (3, 'Budi', 'Madiun', '081311122233'),
    (4, 'Siti', 'Madiun', '081344455566');

INSERT INTO pedagang
    (id_pelaku, id_kios, kategori_usaha)
VALUES
    (1, 1, 'Sayuran'),
    (2, 2, 'Sembako');

INSERT INTO pembeli
    (id_pelaku)
VALUES
    (3),
    (4);

INSERT INTO transaksi
    (id_transaksi, tanggal, metode_pembayaran, total_bayar, id_pembeli, id_pedagang)
VALUES
    (101, '2026-10-01 09:00:00', 'tunai', 39000, 3, 1),
    (102, '2026-10-02 10:00:00', 'qris', 140000, 4, 2);

INSERT INTO detail_transaksi
    (id_detail, id_transaksi, id_barang, jumlah, harga_satuan, subtotal)
VALUES
    (1, 101, 1, 5, 3000, 15000),     -- 5 ikat Bayam
    (2, 101, 2, 2, 12000, 24000),    -- 2 kg Wortel
    (3, 102, 3, 10, 14000, 140000);  -- 10 kg Beras Premium

-- 2.13 Query gabungan: 3 tabel berhubungan (pasar-kios-barang) + 1 tabel relasi (stok)
SELECT
    p.nama_pasar,
    k.nama_kios,
    b.nama_barang,
    b.stok_min,
    s.tanggal,
    s.stok_masuk,
    s.stok_keluar,
    s.stok_akhir,
    CASE
        WHEN s.stok_akhir = 0 THEN 'HABIS'
        WHEN s.stok_akhir < b.stok_min THEN 'MENIPIS'
        ELSE 'AMAN'
    END AS status_stok
FROM pasar p
INNER JOIN kios k ON p.id_pasar = k.id_pasar
INNER JOIN barang b ON k.id_kios = b.id_kios
INNER JOIN stok s ON b.id_barang = s.id_barang
ORDER BY p.nama_pasar, k.nama_kios, b.nama_barang, s.tanggal;

-- 2.14 Query gabungan transaksi (pedagang dan pembeli memakai pelaku_pasar dua kali)
SELECT
    t.id_transaksi,
    t.tanggal,
    pd.nama AS nama_pedagang,
    pb.nama AS nama_pembeli,
    b.nama_barang,
    d.jumlah,
    d.harga_satuan,
    d.subtotal
FROM transaksi t
INNER JOIN pelaku_pasar pd ON t.id_pedagang = pd.id_pelaku
INNER JOIN pelaku_pasar pb ON t.id_pembeli = pb.id_pelaku
INNER JOIN detail_transaksi d ON t.id_transaksi = d.id_transaksi
INNER JOIN barang b ON d.id_barang = b.id_barang
ORDER BY t.id_transaksi, b.nama_barang;


-- =====================================================================
-- TAHAP 3 - CRUD DAN INTEGRITAS REFERENSIAL
-- =====================================================================

-- 3.1 CREATE
INSERT INTO pelaku_pasar
    (nama, alamat, no_hp)
VALUES
    ('Andi', 'Madiun', '081355566677');

SELECT * FROM pelaku_pasar;

-- 3.2 READ
SELECT
    id_pelaku,
    nama,
    no_hp
FROM pelaku_pasar;

SELECT *
FROM barang
WHERE harga_satuan > 10000;

-- 3.3 UPDATE
UPDATE barang
SET harga_satuan = 13000
WHERE id_barang = 2;

SELECT *
FROM barang
WHERE id_barang = 2;

-- (opsional) kembalikan harga awal:
-- UPDATE barang SET harga_satuan = 12000 WHERE id_barang = 2;

-- 3.4 DELETE (Andi belum terdaftar sebagai pedagang/pembeli, jadi berhasil)
DELETE FROM pelaku_pasar
WHERE no_hp = '081355566677';

SELECT * FROM pelaku_pasar;

-- 3.5 UJI INTEGRITAS (SENGAJA GAGAL, jalankan satu per satu, screenshot error)

-- (a) FK: pembeli 999 tidak ada -> GAGAL (error 1452)
INSERT INTO transaksi
    (id_transaksi, tanggal, metode_pembayaran, total_bayar, id_pembeli, id_pedagang)
VALUES
    (105, '2026-10-05 10:00:00', 'tunai', 1000, 999, 1);

-- (b) FK RESTRICT: pembeli 3 (Budi) masih punya transaksi -> GAGAL (error 1451)
DELETE FROM pelaku_pasar
WHERE id_pelaku = 3;

-- (c) FK RESTRICT: kios 1 masih punya barang dan pedagang -> GAGAL (error 1451)
DELETE FROM kios
WHERE id_kios = 1;

-- (d) FK: barang 99 tidak ada -> GAGAL (error 1452)
INSERT INTO detail_transaksi
    (id_transaksi, id_barang, jumlah, harga_satuan, subtotal)
VALUES
    (101, 99, 1, 1000, 1000);

-- (e) UNIQUE: nama pasar kembar -> GAGAL (error 1062)
INSERT INTO pasar
    (nama_pasar, alamat, lokasi)
VALUES
    ('Pasar Sleko', 'Jl. Lain', 'Madiun');

-- (f) CHECK: harga negatif -> GAGAL (error 3819)
INSERT INTO barang
    (id_kios, nama_barang, kategori, harga_satuan, satuan, stok_min)
VALUES
    (1, 'Barang Uji', 'Uji', -5, 'kg', 1);

-- (g) UNIQUE gabungan: stok barang 1 pada tanggal yang sama -> GAGAL (error 1062)
INSERT INTO stok
    (id_barang, tanggal, stok_masuk, stok_keluar, stok_akhir)
VALUES
    (1, '2026-11-10', 10, 0, 10);

-- Analisis: foreign key mencegah transaksi merujuk pembeli, pedagang, atau
-- barang yang tidak ada, dan mencegah penghapusan data induk yang masih dipakai.


-- =====================================================================
-- TAHAP 4 - PENGUJIAN TRANSAKSI DATABASE
-- Jalankan SELURUH blok START TRANSACTION ... COMMIT/ROLLBACK dalam
-- SATU kali klik Go.
-- =====================================================================

-- 4.1 COMMIT: transaksi baru + detailnya tersimpan bersama
START TRANSACTION;

INSERT INTO transaksi
    (id_transaksi, tanggal, metode_pembayaran, total_bayar, id_pembeli, id_pedagang)
VALUES
    (103, '2026-10-05 09:00:00', 'tunai', 36000, 3, 1);

INSERT INTO detail_transaksi
    (id_transaksi, id_barang, jumlah, harga_satuan, subtotal)
VALUES
    (103, 2, 3, 12000, 36000);   -- 3 kg Wortel

COMMIT;

-- Periksa hasil (satu per satu)
SELECT *
FROM transaksi
WHERE id_transaksi = 103;

SELECT *
FROM detail_transaksi
WHERE id_transaksi = 103;

-- Hasil yang diharapkan: transaksi dan detailnya tersimpan.

-- 4.2 ROLLBACK: seluruh perubahan dibatalkan
START TRANSACTION;

INSERT INTO transaksi
    (id_transaksi, tanggal, metode_pembayaran, total_bayar, id_pembeli, id_pedagang)
VALUES
    (104, '2026-10-06 10:00:00', 'qris', 14000, 4, 2);

INSERT INTO detail_transaksi
    (id_transaksi, id_barang, jumlah, harga_satuan, subtotal)
VALUES
    (104, 3, 1, 14000, 14000);

ROLLBACK;

-- Periksa hasil
SELECT *
FROM transaksi
WHERE id_transaksi = 104;

SELECT *
FROM detail_transaksi
WHERE id_transaksi = 104;

-- Hasil yang diharapkan: 0 baris pada kedua query (tidak tersimpan).

-- 4.3 Pertanyaan analisis (jawab di laporan):
--   1. Apa perbedaan COMMIT dan ROLLBACK?
--   2. Mengapa operasi transaksi perlu atomik?
--   3. Apa risiko jika hanya tabel transaksi yang tersimpan tanpa detailnya?
--   4. Mengapa storage engine InnoDB penting pada praktikum ini?


-- =====================================================================
-- TAHAP 6 (bagian kecil) - BACKUP DAN RESTORE SEBELUM DATA MASSAL
-- Disarankan dilakukan di sini, agar file backup kecil.
--
-- phpMyAdmin:
--   Backup : pilih database praktikum_modul10_pasar -> tab Export -> SQL -> Export
--            simpan sebagai backup_modul10.sql
--   Restore: buat database kosong (mis. pasar_restore) -> tab Import ->
--            pilih backup_modul10.sql -> Go
--
-- Command line (buka cmd; XAMPP: C:\xampp\mysql\bin\):
--   mysqldump -u root -p praktikum_modul10_pasar > backup_modul10.sql
--   mysql -u root -p -e "CREATE DATABASE pasar_restore"
--   mysql -u root -p pasar_restore < backup_modul10.sql
-- =====================================================================

-- Validasi (jalankan di database asli dan hasil restore, jumlahnya harus sama)
SELECT 'pasar' AS tabel, COUNT(*) AS jumlah FROM pasar
UNION ALL SELECT 'kios', COUNT(*) FROM kios
UNION ALL SELECT 'barang', COUNT(*) FROM barang
UNION ALL SELECT 'stok', COUNT(*) FROM stok
UNION ALL SELECT 'pelaku_pasar', COUNT(*) FROM pelaku_pasar
UNION ALL SELECT 'pedagang', COUNT(*) FROM pedagang
UNION ALL SELECT 'pembeli', COUNT(*) FROM pembeli
UNION ALL SELECT 'transaksi', COUNT(*) FROM transaksi
UNION ALL SELECT 'detail_transaksi', COUNT(*) FROM detail_transaksi;


-- =====================================================================
-- TAHAP 5 - ANALISIS PERFORMA DATABASE
-- Generate data besar dulu. Jalankan tiap blok dalam SATU kali Go.
-- Jika phpMyAdmin timeout, kecilkan 1000000 menjadi 100000
-- (atau jalankan lewat terminal).
-- =====================================================================

-- 5.1 Generate 1.000 pelaku_pasar sebagai pembeli
SET SESSION cte_max_recursion_depth = 1000000;

INSERT INTO pelaku_pasar (nama, alamat, no_hp)
WITH RECURSIVE seq (n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 1000
)
SELECT
    CONCAT('Pembeli ', n),
    'Madiun',
    CONCAT('08', LPAD(n, 10, '0'))
FROM seq;

INSERT INTO pembeli (id_pelaku)
SELECT id_pelaku
FROM pelaku_pasar
WHERE id_pelaku > 4;

-- 5.2 Generate 1.000.000 transaksi (SATU kali Go, termasuk baris SET)
SET SESSION cte_max_recursion_depth = 1000000;
SET @p0 = (SELECT MIN(id_pelaku) FROM pembeli WHERE id_pelaku > 4);

INSERT INTO transaksi (tanggal, metode_pembayaran, total_bayar, id_pembeli, id_pedagang)
WITH RECURSIVE seq (n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 1000000
)
SELECT
    DATE_ADD('2026-01-01', INTERVAL FLOOR(RAND() * 314 * 86400) SECOND),
    ELT(1 + FLOOR(RAND() * 3), 'tunai', 'transfer', 'qris'),
    0,
    @p0 + FLOOR(RAND() * 1000),
    1 + FLOOR(RAND() * 2)
FROM seq;

-- 5.3 Generate detail (2 barang per transaksi, sekitar 2.000.000 baris)
INSERT INTO detail_transaksi (id_transaksi, id_barang, jumlah, harga_satuan, subtotal)
SELECT
    t.id_transaksi,
    b.id_barang,
    1 + MOD(t.id_transaksi + b.id_barang, 10),
    b.harga_satuan,
    (1 + MOD(t.id_transaksi + b.id_barang, 10)) * b.harga_satuan
FROM transaksi t
INNER JOIN barang b
    ON MOD(t.id_transaksi + b.id_barang, 2) = 0
WHERE t.id_transaksi > 104;

-- 5.4 (Opsional, berat) isi total_bayar data massal dari jumlah subtotal
-- UPDATE transaksi t
-- INNER JOIN (
--     SELECT id_transaksi, SUM(subtotal) AS total
--     FROM detail_transaksi
--     GROUP BY id_transaksi
-- ) d ON d.id_transaksi = t.id_transaksi
-- SET t.total_bayar = d.total
-- WHERE t.id_transaksi > 104;

-- 5.5 Cek jumlah data dan perbarui statistik
SELECT COUNT(*) AS jml_pelaku FROM pelaku_pasar;
SELECT COUNT(*) AS jml_transaksi FROM transaksi;
SELECT COUNT(*) AS jml_detail FROM detail_transaksi;

ANALYZE TABLE pelaku_pasar, transaksi, detail_transaksi;

-- ---------------------------------------------------------------------
-- A. SEBELUM INDEKS (screenshot semua hasil EXPLAIN)
-- ---------------------------------------------------------------------
SHOW INDEX FROM transaksi;

-- Q1: pencarian berdasarkan rentang tanggal
EXPLAIN
SELECT
    id_transaksi,
    id_pembeli,
    tanggal,
    metode_pembayaran
FROM transaksi
WHERE tanggal >= '2026-10-01'
  AND tanggal < '2026-11-01';

-- Q2: pencarian pelaku berdasarkan nama
EXPLAIN
SELECT *
FROM pelaku_pasar
WHERE nama = 'Pembeli 500';

-- Q3: simulasi JOIN + filter tanggal
EXPLAIN
SELECT
    b.nama_barang,
    SUM(d.jumlah) AS total_terjual
FROM transaksi t
INNER JOIN detail_transaksi d ON t.id_transaksi = d.id_transaksi
INNER JOIN barang b ON d.id_barang = b.id_barang
WHERE t.tanggal >= '2026-10-01'
  AND t.tanggal < '2026-11-01'
GROUP BY b.id_barang, b.nama_barang;

-- Catat waktu nyata (MySQL 8):
EXPLAIN ANALYZE
SELECT COUNT(*)
FROM transaksi
WHERE tanggal >= '2026-10-01'
  AND tanggal < '2026-11-01';

-- ---------------------------------------------------------------------
-- B. MEMBUAT INDEKS
-- ---------------------------------------------------------------------
CREATE INDEX idx_transaksi_tanggal
ON transaksi(tanggal);

CREATE INDEX idx_pelaku_nama
ON pelaku_pasar(nama);

ANALYZE TABLE transaksi, pelaku_pasar;

SHOW INDEX FROM transaksi;

SHOW INDEX FROM pelaku_pasar;

-- ---------------------------------------------------------------------
-- C. SESUDAH INDEKS: jalankan query yang SAMA PERSIS
-- ---------------------------------------------------------------------
EXPLAIN
SELECT
    id_transaksi,
    id_pembeli,
    tanggal,
    metode_pembayaran
FROM transaksi
WHERE tanggal >= '2026-10-01'
  AND tanggal < '2026-11-01';

EXPLAIN
SELECT *
FROM pelaku_pasar
WHERE nama = 'Pembeli 500';

EXPLAIN
SELECT
    b.nama_barang,
    SUM(d.jumlah) AS total_terjual
FROM transaksi t
INNER JOIN detail_transaksi d ON t.id_transaksi = d.id_transaksi
INNER JOIN barang b ON d.id_barang = b.id_barang
WHERE t.tanggal >= '2026-10-01'
  AND t.tanggal < '2026-11-01'
GROUP BY b.id_barang, b.nama_barang;

EXPLAIN ANALYZE
SELECT COUNT(*)
FROM transaksi
WHERE tanggal >= '2026-10-01'
  AND tanggal < '2026-11-01';

-- ---------------------------------------------------------------------
-- D. Indeks tidak selalu dipakai: rentang yang mencakup hampir semua baris
-- ---------------------------------------------------------------------
EXPLAIN
SELECT *
FROM transaksi
WHERE tanggal >= '2026-01-01'
  AND tanggal < '2026-12-01';

-- Untuk mengulang percobaan:
-- DROP INDEX idx_transaksi_tanggal ON transaksi;
-- DROP INDEX idx_pelaku_nama ON pelaku_pasar;

-- Bandingkan kolom type, possible_keys, key, rows, dan Extra
-- sebelum dan sesudah indeks.


-- =====================================================================
-- TAHAP 6 (lengkap) - VALIDASI SETELAH RESTORE
-- Setelah data massal, backup penuh bisa sangat besar. Pakai
-- mysqldump --no-data untuk struktur saja bila perlu.
-- =====================================================================
USE praktikum_modul10_pasar;

SHOW TABLES;

SELECT COUNT(*) FROM pasar;
SELECT COUNT(*) FROM kios;
SELECT COUNT(*) FROM barang;
SELECT COUNT(*) FROM stok;
SELECT COUNT(*) FROM pelaku_pasar;
SELECT COUNT(*) FROM pedagang;
SELECT COUNT(*) FROM pembeli;
SELECT COUNT(*) FROM transaksi;
SELECT COUNT(*) FROM detail_transaksi;

-- Catatan keamanan: gunakan hanya data fiktif. Jangan simpan password,
-- kredensial server, atau file backup besar di repositori Git.
