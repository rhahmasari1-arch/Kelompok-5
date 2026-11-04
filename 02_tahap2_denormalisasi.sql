ALTER TABLE pelanggan 
    ADD COLUMN total_belanja DECIMAL(15,2) DEFAULT 0;
UPDATE pelanggan p
SET p.total_belanja = COALESCE((
    SELECT SUM(d.jumlah * d.harga_satuan)
    FROM pesanan ps
    JOIN detail_pesanan d ON d.id_pesanan = ps.id_pesanan
    WHERE ps.id_pelanggan = p.id_pelanggan
), 0);

SELECT id_pelanggan, nama_pelanggan, total_belanja FROM pelanggan;
