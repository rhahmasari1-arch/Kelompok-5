 --membuat data base--
CREATE DATABASE praktikum_pasar;
USE praktikum_pasar;

--Membuat Tabel Pasar--
CREATE TABLE pasar (
    id_pasar INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_pasar VARCHAR(100) NOT NULL UNIQUE,
    alamat VARCHAR(200),
    lokasi VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

--membuat Tabel Kios--
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

--membuat tabel barang--
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

--membuat tabel stok--
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

--memeriksa relasi tabel--
SHOW TABLES;

SHOW CREATE TABLE pasar;

SHOW CREATE TABLE kios;

SHOW CREATE TABLE barang;

SHOW CREATE TABLE stok;

--memasukkan data awal--
