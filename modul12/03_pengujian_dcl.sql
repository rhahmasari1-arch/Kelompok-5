----membuat akun dan memberi hak
CREATE USER IF NOT EXISTS '35ykY1oMv12sNwy.report_user'@'%' IDENTIFIED BY 'Report#2026Pasar';
CREATE USER IF NOT EXISTS '35ykY1oMv12sNwy.operator_user'@'%' IDENTIFIED BY 'Operator#2026Pasar';

-- Staf pelaporan: hanya membaca. Tabel routes ikut diberi hak baca
-- karena query laporan melakukan JOIN ke tabel tersebut.
GRANT SELECT ON transport_db.trips TO '35ykY1oMv12sNwy.report_user'@'%';
GRANT SELECT ON transport_db.routes TO '35ykY1oMv12sNwy.report_user'@'%';

-- Operator lapangan: membaca dan memperbarui data perjalanan, tanpa DELETE.
GRANT SELECT, INSERT, UPDATE ON transport_db.trips TO '35ykY1oMv12sNwy.operator_user'@'%';
GRANT SELECT ON transport_db.routes TO '35ykY1oMv12sNwy.operator_user'@'%';

----memeriksa hak akses
SHOW GRANTS FOR '35ykY1oMv12sNwy.report_user'@'%';
SHOW GRANTS FOR '35ykY1oMv12sNwy.operator_user'@'%';

----pengujian dengan akun report user
mysql --host 127.0.0.1 --port 4000 -u report_user -p transport_db

USE transport_db;
 
-- (1) Baca: harus berhasil
SELECT t.trip_id, t.started_at, r.route_name
FROM trips AS t JOIN routes AS r ON r.route_id = t.route_id
WHERE t.route_id = 12 AND t.started_at >= '2026-11-01';
 
-- (2) Hapus: harus ditolak (ERROR 1142, SQLSTATE 42000)
DELETE FROM trips WHERE trip_id = 'T006';

---pencabutan hak (revoke) dan pengujian ulang
REVOKE SELECT ON transport_db.trips FROM 'RFcVc2pX8RsZYAE.report_user'@'%';
 
SELECT trip_id, started_at FROM trips WHERE route_id = 12;

----show grants
SHOW GRANTS FOR 'RFcVc2pX8RsZYAE.report_user'@'%';
