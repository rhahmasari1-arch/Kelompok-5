-- Memeriksa storage engine InnoDB
SHOW ENGINES;

-- Memeriksa dukungan fungsi JSON
SELECT
    JSON_VALID('{"nama":"Budi"}') AS json_valid,
    JSON_EXTRACT(
        '{"nama":"Budi"}',
        '$.nama'
    ) AS nama;
-- Fasilitas pengelolaan transaksi
Cek pengaturan transaksinya:
SELECT @@autocommit;
SELECT @@transaction_isolation;
buktikan dengan percobaan
START TRANSACTION;
UPDATE stok SET stok_akhir = stok_akhir - 5
WHERE id_barang = 1 AND tanggal = '2026-11-10';
SELECT * FROM stok WHERE id_barang = 1;   -- stok_akhir berkurang 5
ROLLBACK;
SELECT * FROM stok WHERE id_barang = 1;   -- kembali seperti semula

-- 01. DATABASE

DROP DATABASE IF EXISTS praktikum_modul11_pasar;
CREATE DATABASE praktikum_modul11_pasar
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE praktikum_modul11_pasar;

-- 02. TABEL DASAR 

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
-- =====================================================================
ALTER TABLE barang
    ADD COLUMN spesifikasi JSON NULL AFTER stok_min;


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


-- ---------------------------------------------------------------------
-- 03b. KOLOM JSON PADA TABEL KIOS 
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

4.6 Menghapus atribut JSON (promo berakhir)
    SELECT
    nama_barang,
    harga_satuan,
    spesifikasi
FROM barang
WHERE JSON_UNQUOTE(
    JSON_EXTRACT(
        spesifikasi,
        '$.asal'
    )
) = 'Magetan';

-- 4.7 Fungsi JSON lainnya
SELECT JSON_OBJECT(
    'nama', 'Pak Joko',
    'kios', 'Kios Sayur Segar',
    'pasar', 'Pasar Sleko'
) AS data_pedagang;

SELECT JSON_ARRAY('Sayuran', 'Sembako', 'Bumbu', 'Ikan', 'Daging') AS kategori_barang;

SELECT JSON_VALID('{"pasar":"Pasar Sleko","buka":true}') AS json_valid;

SELECT nama_barang, JSON_LENGTH(spesifikasi) AS jumlah_atribut
FROM barang;


-- 4.8 JSON pada tabel kios
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

-- 4.9 JSON pada tabel transaksi
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
