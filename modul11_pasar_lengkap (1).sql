-- =====================================================================
-- Praktikum Modul 11 - Praktik Basis Data (RPL24108)
-- Kasus : Digitalisasi Pasar Tradisional (lanjutan Modul 10)
-- DBMS  : MySQL 8.x (diuji untuk sintaks MySQL 8.4 / MariaDB)
--
-- Skema dasar sama dengan Modul 10:
--   pasar (1) --- (N) kios (1) --- (N) barang (1) --- (N) stok
--   pelaku_pasar  <- supertype
--        +-- pedagang  (id_pelaku, id_kios, kategori_usaha)
--        +-- pembeli   (id_pelaku)
--   pembeli, pedagang --- (N) transaksi (1) --- (N) detail_transaksi --- barang
--   (9 tabel, sama dengan Modul 10)
--
-- Tambahan Modul 11:
--   * kolom barang.spesifikasi (JSON)          : atribut berbeda per jenis barang
--   * kolom kios.info_tambahan (JSON)          : jam operasional, fasilitas, promosi kios
--   * kolom transaksi.detail_pembayaran (JSON) : atribut berbeda per metode pembayaran
--   * view v_barang_objek    : pemetaan barang ke kelas objek
--   * view v_pedagang_objek  : pemetaan pewarisan pelaku_pasar -> pedagang
--
-- Model objek (konseptual):
--
--   Barang                                   <- kelas induk
--   ------------------------------------
--   id_barang, nama_barang, harga_satuan, satuan, stok_min
--   ------------------------------------
--   hitungDiskon(), tampilkanInformasi(), ubahHarga(), cekStokMenipis()
--        |
--        +-- BarangSegar    (kategori Sayuran, Bumbu)  : asal, organik, kesegaran, ...
--        +-- BarangKemasan  (kategori Sembako)         : merek, kemasan, halal, kadaluarsa
--        +-- BarangHewani   (kategori Ikan, Daging)    : jenis, kondisi, halal, potongan[]
--
--   PelakuPasar                              <- kelas induk (tabel pelaku_pasar)
--        +-- Pedagang   (tabel pedagang : id_kios, kategori_usaha)
--        +-- Pembeli    (tabel pembeli)
--
-- PENTING: Modul 10 memuat data massal (1 juta transaksi). Jalankan skrip ini
-- pada database BARU (praktikum_modul11_pasar), bukan pada database Modul 10
-- yang sudah berisi data massal, supaya query tetap cepat.
--
-- Cara pakai:
--   * Database baru      : jalankan seluruh file dari atas.
--   * Melanjutkan DB Modul 10 (praktikum_modul10_pasar): lewati bagian 01 dan
--     02, jalankan USE praktikum_modul10_pasar; lalu mulai dari bagian 03.
-- =====================================================================


-- =====================================================================
-- 01. DATABASE
-- =====================================================================
DROP DATABASE IF EXISTS praktikum_modul11_pasar;
CREATE DATABASE praktikum_modul11_pasar
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE praktikum_modul11_pasar;


-- =====================================================================
-- 02. TABEL DASAR (struktur dan data inti dari Modul 10)
-- =====================================================================
CREATE TABLE pasar (
    id_pasar   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_pasar VARCHAR(100) NOT NULL UNIQUE,
    alamat     VARCHAR(200) DEFAULT NULL,
    lokasi     VARCHAR(100) DEFAULT NULL
) ENGINE=InnoDB;

CREATE TABLE kios (
    id_kios   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_pasar  INT UNSIGNED NOT NULL,
    nama_kios VARCHAR(100) NOT NULL,
    ukuran    VARCHAR(50) DEFAULT NULL,
    CONSTRAINT fk_kios_pasar FOREIGN KEY (id_pasar)
        REFERENCES pasar (id_pasar) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE pelaku_pasar (
    id_pelaku INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama      VARCHAR(100) NOT NULL,
    alamat    VARCHAR(200) DEFAULT NULL,
    no_hp     VARCHAR(20) DEFAULT NULL,
    KEY idx_pelaku_nama (nama)
) ENGINE=InnoDB;

CREATE TABLE pedagang (
    id_pelaku      INT UNSIGNED PRIMARY KEY,
    id_kios        INT UNSIGNED NOT NULL,
    kategori_usaha VARCHAR(100) DEFAULT NULL,
    CONSTRAINT fk_pedagang_pelaku FOREIGN KEY (id_pelaku)
        REFERENCES pelaku_pasar (id_pelaku) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pedagang_kios FOREIGN KEY (id_kios)
        REFERENCES kios (id_kios) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE pembeli (
    id_pelaku INT UNSIGNED PRIMARY KEY,
    CONSTRAINT fk_pembeli_pelaku FOREIGN KEY (id_pelaku)
        REFERENCES pelaku_pasar (id_pelaku) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE barang (
    id_barang    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_kios      INT UNSIGNED NOT NULL,
    nama_barang  VARCHAR(100) NOT NULL,
    kategori     VARCHAR(100) DEFAULT NULL,
    harga_satuan DECIMAL(12,2) NOT NULL,
    satuan       VARCHAR(30) DEFAULT NULL,
    stok_min     INT UNSIGNED NOT NULL DEFAULT 0,
    CONSTRAINT fk_barang_kios FOREIGN KEY (id_kios)
        REFERENCES kios (id_kios) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_harga_barang CHECK (harga_satuan >= 0)
) ENGINE=InnoDB;

CREATE TABLE stok (
    id_stok     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_barang   INT UNSIGNED NOT NULL,
    tanggal     DATE NOT NULL,
    stok_masuk  INT UNSIGNED NOT NULL DEFAULT 0,
    stok_keluar INT UNSIGNED NOT NULL DEFAULT 0,
    stok_akhir  INT UNSIGNED NOT NULL DEFAULT 0,
    UNIQUE KEY uq_stok_barang_tanggal (id_barang, tanggal),
    CONSTRAINT fk_stok_barang FOREIGN KEY (id_barang)
        REFERENCES barang (id_barang) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE transaksi (
    id_transaksi      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tanggal           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metode_pembayaran VARCHAR(50) DEFAULT NULL,
    total_bayar       DECIMAL(14,2) NOT NULL DEFAULT 0,
    id_pembeli        INT UNSIGNED NOT NULL,
    id_pedagang       INT UNSIGNED NOT NULL,
    KEY idx_transaksi_tanggal (tanggal),
    CONSTRAINT fk_transaksi_pembeli FOREIGN KEY (id_pembeli)
        REFERENCES pembeli (id_pelaku) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_transaksi_pedagang FOREIGN KEY (id_pedagang)
        REFERENCES pedagang (id_pelaku) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_total_bayar CHECK (total_bayar >= 0)
) ENGINE=InnoDB;

CREATE TABLE detail_transaksi (
    id_detail    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_transaksi INT UNSIGNED NOT NULL,
    id_barang    INT UNSIGNED NOT NULL,
    jumlah       INT UNSIGNED NOT NULL,
    harga_satuan DECIMAL(12,2) NOT NULL,
    subtotal     DECIMAL(14,2) NOT NULL,
    CONSTRAINT fk_detail_transaksi FOREIGN KEY (id_transaksi)
        REFERENCES transaksi (id_transaksi) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_detail_barang FOREIGN KEY (id_barang)
        REFERENCES barang (id_barang) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_jumlah_detail CHECK (jumlah > 0),
    CONSTRAINT chk_harga_detail CHECK (harga_satuan >= 0),
    CONSTRAINT chk_subtotal_detail CHECK (subtotal >= 0)
) ENGINE=InnoDB;

-- Data inti (sama dengan Modul 10)
INSERT INTO pasar (id_pasar, nama_pasar, alamat, lokasi) VALUES
(1, 'Pasar Sleko',  'Jl. Pasar Sleko No. 1', 'Madiun'),
(2, 'Pasar Besar',  'Jl. Pasar Besar No. 5', 'Madiun');

INSERT INTO kios (id_kios, id_pasar, nama_kios, ukuran) VALUES
(1, 1, 'Kios Sayur Segar',   '3x3 m'),
(2, 1, 'Kios Beras Makmur',  '4x3 m'),
(3, 2, 'Kios Bumbu Jaya',    '2x3 m');

INSERT INTO pelaku_pasar (id_pelaku, nama, alamat, no_hp) VALUES
(1, 'Pak Joko', 'Madiun', '081234567890'),
(2, 'Bu Sari',  'Madiun', '081298765432'),
(3, 'Budi',     'Madiun', '081311122233'),
(4, 'Siti',     'Madiun', '081344455566');

INSERT INTO pedagang (id_pelaku, id_kios, kategori_usaha) VALUES
(1, 1, 'Sayuran'),
(2, 2, 'Sembako');

INSERT INTO pembeli (id_pelaku) VALUES (3), (4);

INSERT INTO barang (id_barang, id_kios, nama_barang, kategori, harga_satuan, satuan, stok_min) VALUES
(1, 1, 'Bayam',         'Sayuran', 3000.00,  'ikat', 20),
(2, 1, 'Wortel',        'Sayuran', 12000.00, 'kg',   15),
(3, 2, 'Beras Premium', 'Sembako', 14000.00, 'kg',   50),
(4, 3, 'Bawang Merah',  'Bumbu',   35000.00, 'kg',   10);

INSERT INTO stok (id_stok, id_barang, tanggal, stok_masuk, stok_keluar, stok_akhir) VALUES
(1, 1, '2026-11-09', 50,  20, 30),
(2, 1, '2026-11-10', 40,  45, 25),
(3, 2, '2026-11-10', 30,  22, 8),
(4, 3, '2026-11-10', 100, 30, 70),
(5, 4, '2026-11-10', 20,  12, 8);

INSERT INTO transaksi (id_transaksi, tanggal, metode_pembayaran, total_bayar, id_pembeli, id_pedagang) VALUES
(101, '2026-10-01 09:00:00', 'tunai', 39000,  3, 1),
(102, '2026-10-02 10:00:00', 'qris',  140000, 4, 2);

INSERT INTO detail_transaksi (id_detail, id_transaksi, id_barang, jumlah, harga_satuan, subtotal) VALUES
(1, 101, 1, 5,  3000,  15000),    -- 5 ikat Bayam
(2, 101, 2, 2,  12000, 24000),    -- 2 kg Wortel
(3, 102, 3, 10, 14000, 140000);   -- 10 kg Beras Premium


-- =====================================================================
-- 03. TAMBAH KOLOM JSON PADA TABEL BARANG
--     Atribut yang sama untuk semua barang (harga, satuan, stok_min) tetap
--     berupa kolom. Atribut yang berbeda per jenis barang masuk ke JSON.
-- =====================================================================
ALTER TABLE barang
    ADD COLUMN spesifikasi JSON NULL AFTER stok_min;

-- Isi spesifikasi untuk 4 barang dari Modul 10 (atribut tiap barang berbeda)
UPDATE barang SET spesifikasi = '{
    "asal": "Dusun Sari",
    "organik": true,
    "kesegaran": "panen hari ini",
    "berat_per_ikat": "250g"
}' WHERE id_barang = 1;

UPDATE barang SET spesifikasi = '{
    "asal": "Magetan",
    "organik": false,
    "warna": "oranye"
}' WHERE id_barang = 2;

UPDATE barang SET spesifikasi = '{
    "merek": "Pandan Wangi",
    "kemasan": "karung 25kg",
    "halal": true,
    "kadaluarsa": "2027-06-30"
}' WHERE id_barang = 3;

UPDATE barang SET spesifikasi = '{
    "asal": "Nganjuk",
    "kualitas": "super",
    "ukuran_umbi": "sedang"
}' WHERE id_barang = 4;

-- Kios dan pedagang baru (ikan dan daging) supaya ada jenis barang lain
INSERT INTO kios (id_pasar, nama_kios, ukuran)
VALUES (1, 'Kios Ikan dan Ayam', '3x2 m');

INSERT INTO pelaku_pasar (nama, alamat, no_hp)
VALUES ('Pak Hasan', 'Madiun', '081355566677');

INSERT INTO pedagang (id_pelaku, id_kios, kategori_usaha)
VALUES (
    (SELECT id_pelaku FROM pelaku_pasar WHERE nama = 'Pak Hasan' LIMIT 1),
    (SELECT id_kios FROM kios WHERE nama_kios = 'Kios Ikan dan Ayam' LIMIT 1),
    'Ikan dan Daging'
);

-- Barang baru dengan atribut JSON berbeda
INSERT INTO barang (id_kios, nama_barang, kategori, harga_satuan, satuan, stok_min, spesifikasi)
VALUES (
    (SELECT id_kios FROM kios WHERE nama_kios = 'Kios Ikan dan Ayam'),
    'Ikan Lele', 'Ikan', 28000.00, 'kg', 10,
    '{
        "jenis": "ikan air tawar",
        "kondisi": "segar",
        "bisa_dibersihkan": true,
        "asal": "Kolam Ngawi"
    }'
);

INSERT INTO barang (id_kios, nama_barang, kategori, harga_satuan, satuan, stok_min, spesifikasi)
VALUES (
    (SELECT id_kios FROM kios WHERE nama_kios = 'Kios Ikan dan Ayam'),
    'Ayam Potong', 'Daging', 38000.00, 'kg', 10,
    '{
        "jenis": "ayam broiler",
        "kondisi": "segar",
        "halal": true,
        "potongan": [
            "dada",
            "paha",
            "sayap"
        ]
    }'
);

INSERT INTO barang (id_kios, nama_barang, kategori, harga_satuan, satuan, stok_min, spesifikasi)
VALUES (
    3, 'Cabai Rawit Merah', 'Bumbu', 45000.00, 'kg', 5,
    '{
        "asal": "Kediri",
        "organik": false,
        "tingkat_pedas": "tinggi"
    }'
);

SELECT id_barang, nama_barang, kategori, harga_satuan, satuan, spesifikasi
FROM barang;


-- ---------------------------------------------------------------------
-- 03b. KOLOM JSON PADA TABEL KIOS (KF-06 jam operasional, KF-07 promosi)
-- ---------------------------------------------------------------------
ALTER TABLE kios
    ADD COLUMN info_tambahan JSON NULL AFTER ukuran;

UPDATE kios SET info_tambahan = '{
    "jam_operasional": "04:00-12:00",
    "fasilitas": ["timbangan digital", "QRIS"],
    "promosi": "Gratis 1 ikat bayam untuk belanja Rp50.000"
}' WHERE nama_kios = 'Kios Sayur Segar';

UPDATE kios SET info_tambahan = '{
    "jam_operasional": "05:00-15:00",
    "fasilitas": ["QRIS", "parkir"]
}' WHERE nama_kios = 'Kios Beras Makmur';

UPDATE kios SET info_tambahan = '{
    "jam_operasional": "05:00-14:00",
    "fasilitas": ["timbangan digital"]
}' WHERE nama_kios = 'Kios Bumbu Jaya';

UPDATE kios SET info_tambahan = '{
    "jam_operasional": "04:00-11:00",
    "fasilitas": ["freezer", "QRIS"]
}' WHERE nama_kios = 'Kios Ikan dan Ayam';

-- ---------------------------------------------------------------------
-- 03c. KOLOM JSON PADA TABEL TRANSAKSI (KF-10 pembayaran digital, D6)
--      Atribut pembayaran berbeda tiap metode: tunai vs QRIS.
-- ---------------------------------------------------------------------
ALTER TABLE transaksi
    ADD COLUMN detail_pembayaran JSON NULL;

UPDATE transaksi SET detail_pembayaran =
    JSON_OBJECT('uang_diterima', 50000, 'kembalian', 11000)
WHERE id_transaksi = 101;                                   -- tunai

UPDATE transaksi SET detail_pembayaran =
    JSON_OBJECT('penyedia', 'QRIS', 'id_referensi', 'QR-20261002-0001', 'status', 'berhasil')
WHERE id_transaksi = 102;                                   -- qris

SELECT nama_kios, info_tambahan FROM kios;
SELECT id_transaksi, metode_pembayaran, total_bayar, detail_pembayaran FROM transaksi;


-- =====================================================================
-- 04. PENGUJIAN JSON
-- =====================================================================

-- 4.1 Membaca atribut JSON
-- Atribut yang tidak dimiliki suatu barang akan bernilai NULL
SELECT nama_barang, JSON_EXTRACT(spesifikasi, '$.asal') AS asal
FROM barang;

SELECT nama_barang, JSON_EXTRACT(spesifikasi, '$.merek') AS merek
FROM barang;

SELECT nama_barang, JSON_EXTRACT(spesifikasi, '$.potongan') AS potongan
FROM barang;

-- 4.2 Mencari barang berdasarkan atribut JSON
-- Barang yang berasal dari Magetan
SELECT nama_barang, harga_satuan, satuan
FROM barang
WHERE JSON_UNQUOTE(JSON_EXTRACT(spesifikasi, '$.asal')) = 'Magetan';

-- Barang organik (nilai boolean true)
SELECT nama_barang, harga_satuan
FROM barang
WHERE JSON_CONTAINS(spesifikasi, 'true', '$.organik');

-- Barang halal bersertifikat
SELECT nama_barang, kategori
FROM barang
WHERE JSON_CONTAINS(spesifikasi, 'true', '$.halal');

-- Pencarian di dalam array: ayam yang tersedia potongan paha
SELECT nama_barang, harga_satuan
FROM barang
WHERE JSON_CONTAINS(spesifikasi, '"paha"', '$.potongan');

-- 4.3 Mengubah atribut JSON (kesegaran bayam berubah)
UPDATE barang
SET spesifikasi = JSON_SET(spesifikasi, '$.kesegaran', 'panen kemarin')
WHERE nama_barang = 'Bayam';

SELECT nama_barang, JSON_EXTRACT(spesifikasi, '$.kesegaran') AS kesegaran
FROM barang
WHERE nama_barang = 'Bayam';

-- 4.4 Menambahkan atribut JSON (promo pada wortel)
UPDATE barang
SET spesifikasi = JSON_SET(spesifikasi, '$.promo', 'Diskon 10% sebelum jam 08.00')
WHERE nama_barang = 'Wortel';

SELECT nama_barang, spesifikasi
FROM barang
WHERE nama_barang = 'Wortel';

-- 4.5 Menghapus atribut JSON (promo berakhir)
UPDATE barang
SET spesifikasi = JSON_REMOVE(spesifikasi, '$.promo')
WHERE nama_barang = 'Wortel';

SELECT nama_barang, spesifikasi FROM barang;

-- 4.6 Fungsi JSON lainnya
SELECT JSON_OBJECT(
    'nama', 'Pak Joko',
    'kios', 'Kios Sayur Segar',
    'pasar', 'Pasar Sleko'
) AS data_pedagang;

SELECT JSON_ARRAY('Sayuran', 'Sembako', 'Bumbu', 'Ikan', 'Daging') AS kategori_barang;

SELECT JSON_VALID('{"pasar":"Pasar Sleko","buka":true}') AS json_valid;

SELECT nama_barang, JSON_LENGTH(spesifikasi) AS jumlah_atribut
FROM barang;


-- 4.7 JSON pada tabel kios
-- Jam operasional setiap kios
SELECT nama_kios,
       JSON_UNQUOTE(JSON_EXTRACT(info_tambahan, '$.jam_operasional')) AS jam_operasional
FROM kios;

-- Kios yang melayani pembayaran QRIS (pencarian di dalam array)
SELECT nama_kios
FROM kios
WHERE JSON_CONTAINS(info_tambahan, '"QRIS"', '$.fasilitas');

-- Ubah jam operasional
UPDATE kios
SET info_tambahan = JSON_SET(info_tambahan, '$.jam_operasional', '04:00-13:00')
WHERE nama_kios = 'Kios Sayur Segar';

-- Tambah, lalu hapus atribut promosi pada kios beras
UPDATE kios
SET info_tambahan = JSON_SET(info_tambahan, '$.promosi', 'Beras 5kg gratis ongkos angkut')
WHERE nama_kios = 'Kios Beras Makmur';

UPDATE kios
SET info_tambahan = JSON_REMOVE(info_tambahan, '$.promosi')
WHERE nama_kios = 'Kios Beras Makmur';

SELECT nama_kios, info_tambahan FROM kios;

-- 4.8 JSON pada tabel transaksi
-- Pembayaran QRIS yang berhasil
SELECT id_transaksi, total_bayar
FROM transaksi
WHERE JSON_UNQUOTE(JSON_EXTRACT(detail_pembayaran, '$.status')) = 'berhasil';

-- Kembalian pada pembayaran tunai
SELECT id_transaksi, total_bayar,
       JSON_EXTRACT(detail_pembayaran, '$.kembalian') AS kembalian
FROM transaksi
WHERE metode_pembayaran = 'tunai';

-- Tambah, lalu hapus catatan pada transaksi QRIS
UPDATE transaksi
SET detail_pembayaran = JSON_SET(detail_pembayaran, '$.catatan', 'dikonfirmasi pedagang')
WHERE id_transaksi = 102;

UPDATE transaksi
SET detail_pembayaran = JSON_REMOVE(detail_pembayaran, '$.catatan')
WHERE id_transaksi = 102;

SELECT id_transaksi, detail_pembayaran FROM transaksi;


-- =====================================================================
-- 05. PEMODELAN OBJEK DI DBMS RELASIONAL
-- =====================================================================

-- 5.1 Barang -> kelas objek.
--     Kolom kategori berfungsi sebagai penentu kelas turunan (discriminator),
--     atribut khusus kelas turunan disimpan di kolom JSON.
CREATE VIEW v_barang_objek AS
SELECT
    b.id_barang,
    b.nama_barang,
    CASE
        WHEN b.kategori IN ('Sayuran', 'Bumbu') THEN 'BarangSegar'
        WHEN b.kategori = 'Sembako'             THEN 'BarangKemasan'
        WHEN b.kategori IN ('Ikan', 'Daging')   THEN 'BarangHewani'
        ELSE 'Barang'
    END AS kelas_objek,
    b.harga_satuan,
    b.satuan,
    b.spesifikasi
FROM barang b;

SELECT id_barang, nama_barang, harga_satuan, spesifikasi
FROM v_barang_objek
WHERE kelas_objek = 'BarangSegar';

SELECT id_barang, nama_barang, harga_satuan, spesifikasi
FROM v_barang_objek
WHERE kelas_objek = 'BarangKemasan';

SELECT id_barang, nama_barang, harga_satuan, spesifikasi
FROM v_barang_objek
WHERE kelas_objek = 'BarangHewani';

-- 5.2 Pewarisan PelakuPasar -> Pedagang pada Modul 10 (class table inheritance):
--     atribut umum ada di pelaku_pasar, atribut khusus ada di pedagang.
CREATE VIEW v_pedagang_objek AS
SELECT
    pl.id_pelaku,
    pl.nama,
    pl.no_hp,
    'Pedagang'   AS kelas_objek,
    pd.kategori_usaha,
    k.nama_kios,
    ps.nama_pasar
FROM pelaku_pasar pl
JOIN pedagang pd ON pd.id_pelaku = pl.id_pelaku
JOIN kios k      ON k.id_kios    = pd.id_kios
JOIN pasar ps    ON ps.id_pasar  = k.id_pasar;

SELECT * FROM v_pedagang_objek;

-- 5.3 Menggabungkan data relasional dan JSON
SELECT
    b.id_barang,
    b.nama_barang,
    k.nama_kios,
    ps.nama_pasar,
    b.harga_satuan,
    b.satuan,
    JSON_EXTRACT(b.spesifikasi, '$.asal') AS asal
FROM barang b
JOIN kios k   ON k.id_kios   = b.id_kios
JOIN pasar ps ON ps.id_pasar = k.id_pasar;

-- 5.4 Barang yang stoknya menipis pada tanggal terakhir, lengkap dengan JSON
SELECT
    b.nama_barang,
    s.tanggal,
    s.stok_akhir,
    b.stok_min,
    JSON_EXTRACT(b.spesifikasi, '$.asal') AS asal
FROM barang b
JOIN stok s ON s.id_barang = b.id_barang
WHERE s.tanggal = (SELECT MAX(s2.tanggal) FROM stok s2 WHERE s2.id_barang = b.id_barang)
  AND s.stok_akhir < b.stok_min;

-- 5.5 Rincian transaksi beserta atribut JSON barang
SELECT
    t.id_transaksi,
    t.tanggal,
    pd.nama AS nama_pedagang,
    pb.nama AS nama_pembeli,
    b.nama_barang,
    d.jumlah,
    d.subtotal,
    JSON_EXTRACT(b.spesifikasi, '$.asal') AS asal
FROM transaksi t
JOIN pelaku_pasar pd    ON pd.id_pelaku = t.id_pedagang
JOIN pelaku_pasar pb    ON pb.id_pelaku = t.id_pembeli
JOIN detail_transaksi d ON d.id_transaksi = t.id_transaksi
JOIN barang b           ON b.id_barang = d.id_barang
ORDER BY t.id_transaksi, b.nama_barang;

-- 5.6 Penjualan barang organik (filter JSON + agregasi transaksi)
SELECT
    b.nama_barang,
    SUM(d.jumlah)   AS total_terjual,
    SUM(d.subtotal) AS total_rupiah
FROM detail_transaksi d
JOIN barang b ON b.id_barang = d.id_barang
WHERE JSON_CONTAINS(b.spesifikasi, 'true', '$.organik')
GROUP BY b.id_barang, b.nama_barang;

-- 5.7 Pendapatan per kelas objek (memakai view v_barang_objek)
SELECT
    v.kelas_objek,
    SUM(d.jumlah)   AS total_terjual,
    SUM(d.subtotal) AS total_rupiah
FROM detail_transaksi d
JOIN v_barang_objek v ON v.id_barang = d.id_barang
GROUP BY v.kelas_objek;


-- =====================================================================
-- 06. BONUS: TRANSAKSI (ACID pada InnoDB)
--     Pesanan baru (transaksi + detail + pengurangan stok) dibatalkan
--     seluruhnya dengan ROLLBACK. Jalankan blok ini dalam SATU kali Go.
-- =====================================================================
START TRANSACTION;

INSERT INTO transaksi (id_transaksi, tanggal, metode_pembayaran, total_bayar, id_pembeli, id_pedagang)
VALUES (103, '2026-11-11 08:00:00', 'qris', 15000, 3, 1);

INSERT INTO detail_transaksi (id_transaksi, id_barang, jumlah, harga_satuan, subtotal)
VALUES (103, 1, 5, 3000, 15000);

UPDATE stok
SET stok_keluar = stok_keluar + 5,
    stok_akhir  = stok_akhir - 5
WHERE id_barang = 1 AND tanggal = '2026-11-10';

SELECT id_barang, tanggal, stok_keluar, stok_akhir
FROM stok WHERE id_barang = 1 AND tanggal = '2026-11-10';   -- stok_akhir 20
SELECT COUNT(*) AS jumlah_transaksi FROM transaksi;          -- 3

ROLLBACK;

SELECT id_barang, tanggal, stok_keluar, stok_akhir
FROM stok WHERE id_barang = 1 AND tanggal = '2026-11-10';   -- kembali 25
SELECT COUNT(*) AS jumlah_transaksi FROM transaksi;          -- kembali 2


-- =====================================================================
-- 07. BONUS: INDEKS PADA ATRIBUT JSON (generated column)
--     Pencarian berdasarkan asal barang menjadi lebih cepat.
-- =====================================================================
ALTER TABLE barang
    ADD COLUMN asal_barang VARCHAR(100)
        GENERATED ALWAYS AS (JSON_UNQUOTE(JSON_EXTRACT(spesifikasi, '$.asal'))) VIRTUAL,
    ADD INDEX idx_barang_asal (asal_barang);

SELECT nama_barang, asal_barang
FROM barang
WHERE asal_barang = 'Kediri';
