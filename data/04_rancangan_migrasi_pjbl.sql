----RANCANGAN SKEMA DAN QUERY PADA TIDB
CREATE DATABASE IF NOT EXISTS pasar_tidb;
USE pasar_tidb;
 
-- CHECK constraint tidak aktif secara bawaan pada TiDB.
-- Aktifkan sebelum CREATE TABLE.
SET GLOBAL tidb_enable_check_constraint = ON;
 
CREATE TABLE pasar (
    id_pasar   INT PRIMARY KEY,
    nama_pasar VARCHAR(100) NOT NULL,
    alamat     VARCHAR(255) NOT NULL,
    lokasi     VARCHAR(100),
    jam_buka   TIME,
    jam_tutup  TIME
);
 
CREATE TABLE pelaku_pasar (
    id_pelaku     BIGINT PRIMARY KEY AUTO_RANDOM,
    nama          VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    no_hp         VARCHAR(20),
    alamat        VARCHAR(255),
    peran         ENUM('pedagang', 'pembeli') NOT NULL,
    status_akun   ENUM('aktif', 'nonaktif') NOT NULL DEFAULT 'aktif'
);
 
CREATE TABLE kategori (
    id_kategori   INT PRIMARY KEY,
    nama_kategori VARCHAR(100) NOT NULL UNIQUE
);
 
CREATE TABLE kios (
    id_kios     BIGINT PRIMARY KEY AUTO_RANDOM,
    id_pasar    INT NOT NULL,
    id_pedagang BIGINT NOT NULL,
    nomor_kios  VARCHAR(10) NOT NULL,
    nama_kios   VARCHAR(100) NOT NULL,
    ukuran      VARCHAR(20),
    UNIQUE KEY uq_kios (id_pasar, nomor_kios),
    FOREIGN KEY (id_pasar)    REFERENCES pasar (id_pasar),
    FOREIGN KEY (id_pedagang) REFERENCES pelaku_pasar (id_pelaku)
);
 
CREATE TABLE barang (
    id_barang    BIGINT PRIMARY KEY AUTO_RANDOM,
    id_kios      BIGINT NOT NULL,
    id_kategori  INT NOT NULL,
    nama_barang  VARCHAR(100) NOT NULL,
    harga        DECIMAL(12,2) NOT NULL CHECK (harga >= 0),
    stok         INT NOT NULL DEFAULT 0 CHECK (stok >= 0),
    info_promosi JSON,
    FOREIGN KEY (id_kios)     REFERENCES kios (id_kios),
    FOREIGN KEY (id_kategori) REFERENCES kategori (id_kategori),
    -- pencarian barang (KF-04) dengan pola awalan
    INDEX idx_barang_nama (nama_barang)
);
 
CREATE TABLE transaksi (
    id_transaksi      BIGINT PRIMARY KEY AUTO_RANDOM,
    id_pembeli        BIGINT NOT NULL,
    tanggal           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metode_pembayaran ENUM('qris', 'tunai') NOT NULL,
    status_pesanan    ENUM('menunggu', 'dikonfirmasi', 'ditolak', 'selesai', 'dibatalkan')
                      NOT NULL DEFAULT 'menunggu',
    status_pembayaran ENUM('belum_bayar', 'berhasil', 'gagal')
                      NOT NULL DEFAULT 'belum_bayar',
    total_bayar       DECIMAL(14,2) NOT NULL DEFAULT 0 CHECK (total_bayar >= 0),
    FOREIGN KEY (id_pembeli) REFERENCES pelaku_pasar (id_pelaku),
    INDEX idx_transaksi_status_tgl (status_pesanan, tanggal)
);
 
CREATE TABLE detail_transaksi (
    id_detail          BIGINT PRIMARY KEY AUTO_RANDOM,
    id_transaksi       BIGINT NOT NULL,
    id_barang          BIGINT NOT NULL,
    jumlah             INT NOT NULL CHECK (jumlah > 0),
    harga_saat_dipesan DECIMAL(12,2) NOT NULL,
    subtotal           DECIMAL(14,2) NOT NULL,
    CHECK (subtotal = ROUND(jumlah * harga_saat_dipesan, 2)),
    FOREIGN KEY (id_transaksi) REFERENCES transaksi (id_transaksi),
    FOREIGN KEY (id_barang)    REFERENCES barang (id_barang),
    -- covering index (pengganti STORING pada DBMS lain)
    INDEX idx_detail_transaksi (id_transaksi, id_barang, jumlah, subtotal)
);

SELECT k.nomor_kios, k.nama_kios, g.nama_kategori,
       SUM(d.jumlah)   AS total_barang,
       SUM(d.subtotal) AS total_rupiah
FROM detail_transaksi d
JOIN transaksi t  ON t.id_transaksi = d.id_transaksi
JOIN barang b     ON b.id_barang    = d.id_barang
JOIN kios k       ON k.id_kios      = b.id_kios
JOIN kategori g   ON g.id_kategori  = b.id_kategori
WHERE t.status_pesanan = 'selesai'
  AND t.tanggal >= '2026-11-01'
  AND t.tanggal <  '2026-12-01'
GROUP BY k.id_kios, k.nomor_kios, k.nama_kios, g.nama_kategori
ORDER BY k.nomor_kios, g.nama_kategori;

----RANCANGAN KONTROL AKSES (LEAST PRIVILLEGE)
CREATE VIEW v_rekap_penjualan_kios AS
SELECT k.id_pedagang, k.nomor_kios, k.nama_kios,
       DATE_FORMAT(t.tanggal, '%Y-%m-01') AS bulan,
       g.nama_kategori,
       SUM(d.jumlah)   AS total_barang,
       SUM(d.subtotal) AS total_rupiah
FROM detail_transaksi d
JOIN transaksi t  ON t.id_transaksi = d.id_transaksi
JOIN barang b     ON b.id_barang    = d.id_barang
JOIN kios k       ON k.id_kios      = b.id_kios
JOIN kategori g   ON g.id_kategori  = b.id_kategori
WHERE t.status_pesanan = 'selesai'
GROUP BY k.id_kios, k.id_pedagang, k.nomor_kios, k.nama_kios,
         DATE_FORMAT(t.tanggal, '%Y-%m-01'), g.nama_kategori;
 
CREATE ROLE IF NOT EXISTS role_pembeli;
CREATE ROLE IF NOT EXISTS role_pedagang;
CREATE ROLE IF NOT EXISTS role_pembayaran;
CREATE ROLE IF NOT EXISTS role_auth;
 
-- Pembeli: baca katalog, buat dan lihat pesanan
GRANT SELECT ON pasar_tidb.pasar    TO role_pembeli;
GRANT SELECT ON pasar_tidb.kios     TO role_pembeli;
GRANT SELECT ON pasar_tidb.kategori TO role_pembeli;
GRANT SELECT ON pasar_tidb.barang   TO role_pembeli;
GRANT SELECT, INSERT ON pasar_tidb.transaksi        TO role_pembeli;
GRANT SELECT, INSERT ON pasar_tidb.detail_transaksi TO role_pembeli;
 
-- Pedagang: kelola barang dan kios, konfirmasi pesanan, lihat laporan
GRANT SELECT, INSERT, UPDATE, DELETE ON pasar_tidb.barang TO role_pedagang;
GRANT SELECT, INSERT, UPDATE ON pasar_tidb.kios           TO role_pedagang;
GRANT SELECT, UPDATE ON pasar_tidb.transaksi              TO role_pedagang;
GRANT SELECT ON pasar_tidb.detail_transaksi               TO role_pedagang;
GRANT SELECT ON pasar_tidb.kategori                       TO role_pedagang;
GRANT SELECT ON pasar_tidb.pasar                          TO role_pedagang;
GRANT SELECT ON pasar_tidb.v_rekap_penjualan_kios         TO role_pedagang;
 
-- Layanan pembayaran: perbarui status transaksi
GRANT SELECT, UPDATE ON pasar_tidb.transaksi TO role_pembayaran;
 
-- Pengelolaan akun
GRANT SELECT, INSERT, UPDATE ON pasar_tidb.pelaku_pasar TO role_auth;
 
-- TiDB Cloud mewajibkan prefix cluster pada nama akun (sama seperti Tahap 4)
CREATE USER IF NOT EXISTS '35ykY1oMv12sNwy.pembeli_app'@'%'    IDENTIFIED BY 'GANTI_DENGAN_PASSWORD_KUAT';
CREATE USER IF NOT EXISTS '35ykY1oMv12sNwy.pedagang_app'@'%'   IDENTIFIED BY 'GANTI_DENGAN_PASSWORD_KUAT';
CREATE USER IF NOT EXISTS '35ykY1oMv12sNwy.pembayaran_app'@'%' IDENTIFIED BY 'GANTI_DENGAN_PASSWORD_KUAT';
CREATE USER IF NOT EXISTS '35ykY1oMv12sNwy.auth_app'@'%'       IDENTIFIED BY 'GANTI_DENGAN_PASSWORD_KUAT';
 
GRANT role_pembeli    TO '35ykY1oMv12sNwy.pembeli_app'@'%';
GRANT role_pedagang   TO '35ykY1oMv12sNwy.pedagang_app'@'%';
GRANT role_pembayaran TO '35ykY1oMv12sNwy.pembayaran_app'@'%';
GRANT role_auth       TO '35ykY1oMv12sNwy.auth_app'@'%';
 
-- Role harus diaktifkan agar haknya berlaku saat akun login
SET DEFAULT ROLE role_pembeli    TO '35ykY1oMv12sNwy.pembeli_app'@'%';
SET DEFAULT ROLE role_pedagang   TO '35ykY1oMv12sNwy.pedagang_app'@'%';
SET DEFAULT ROLE role_pembayaran TO '35ykY1oMv12sNwy.pembayaran_app'@'%';
SET DEFAULT ROLE role_auth       TO '35ykY1oMv12sNwy.auth_app'@'%';
 
SHOW GRANTS FOR '35ykY1oMv12sNwy.pembeli_app'@'%'    USING role_pembeli;
SHOW GRANTS FOR '35ykY1oMv12sNwy.pedagang_app'@'%'   USING role_pedagang;
SHOW GRANTS FOR '35ykY1oMv12sNwy.pembayaran_app'@'%' USING role_pembayaran;
SHOW GRANTS FOR '35ykY1oMv12sNwy.auth_app'@'%'       USING role_auth;
