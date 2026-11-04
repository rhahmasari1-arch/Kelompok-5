
SELECT p.id_pelanggan, p.nama_pelanggan,
       COUNT(DISTINCT ps.id_pesanan)  AS jumlah_pesanan,
       SUM(d.jumlah * d.harga_satuan) AS total_belanja
FROM pelanggan p
JOIN pesanan ps       ON ps.id_pelanggan = p.id_pelanggan
JOIN detail_pesanan d ON d.id_pesanan    = ps.id_pesanan
GROUP BY p.id_pelanggan, p.nama_pelanggan
ORDER BY total_belanja DESC
LIMIT 10;


