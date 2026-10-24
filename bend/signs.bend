# lajur — the sign catalogue: every rambu PM 13/2014 lists, table by table.
#
# The regulation enumerates signs by a code inside each Lampiran table, so a
# code alone is ambiguous: 1a is a warning sign in Tabel II and a piktogram in
# Tabel I. The catalogue keys each sign by table and code, written "II-1a".
# The code after the dash is the regulation's own code, unchanged. A code that
# the table gives two names carries both, separated by "; ".
#
# `ordinal` is the sign's position in the catalogue. It is not printed on a
# sign; it is what lets a proof notice a deleted or reordered entry.
import Base
import ./model.bend as M

type Table is Data:
  Elektronik{}
  Peringatan{}
  Larangan{}
  Perintah{}
  Petunjuk{}
  PeringatanSementara{}
  PapanTambahan{}

type Sign is Data:
  Sign{code: String, table: Table, group: String, family: M.Sign, meaning: String, ordinal: U32}

type Group is Data:
  Group{name: String, table: Table, size: U32}

type Supplement is Data:
  Supplement{group: String, meaning: String, ordinal: U32}

# ---------------------------------------------------------------------------
# The catalogue
# ---------------------------------------------------------------------------

def signs() -> List<&2, Sign>:
  [
    Sign{"I-1a", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kiri dan Kanan", 1}
  , Sign{"I-1b", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kiri dan Kanan", 2}
  , Sign{"I-1c", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kiri", 3}
  , Sign{"I-1d", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kanan", 4}
  , Sign{"I-1e", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kiri", 5}
  , Sign{"I-1f", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kanan", 6}
  , Sign{"I-1g", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pengurangan Lajur Kiri", 7}
  , Sign{"I-1h", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pengurangan Lajur Kanan", 8}
  , Sign{"I-1i", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Penambahan Lajur Kiri", 9}
  , Sign{"I-1j", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Penambahan Lajur Kanan", 10}
  , Sign{"I-1k", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Jembatan; Peringatan Penyempitan Bagan Jalinan Jalan Tertentu", 11}
  , Sign{"I-1l", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Permukaan Jalan yang Licin", 12}
  , Sign{"I-1m", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Lontaran Kerikil", 13}
  , Sign{"I-1n", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Telah Terjadi Longsor pada Sebelah Kiri Sisi Jalan", 14}
  , Sign{"I-1o", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Telah Terjadi Longsor pada Sebelah Kanan Sisi Jalan", 15}
  , Sign{"I-1p", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Banyak Lalu Lintas Pejalan Kaki", 16}
  , Sign{"I-1q", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Banyak Lalu Lintas Pejalan Kaki Anak-anak", 17}
  , Sign{"I-1r", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Banyak Lalu Lintas Penyandang Cacat", 18}
  , Sign{"I-1s", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Banyak Lalu Lintas Sepeda", 19}
  , Sign{"I-1t", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Banyak Hewan Ternak Melintas", 20}
  , Sign{"I-1u", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Banyak Hewan Liar Melintas", 21}
  , Sign{"I-1v", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Kondisi Lalu Lintas Padat", 22}
  , Sign{"I-1w", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Kecelakaan Tunggal", 23}
  , Sign{"I-1x", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Kecelakaan Ganda", 24}
  , Sign{"I-1y", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Kondisi Cuaca Berkabut", 25}
  , Sign{"I-1z", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Kondisi Cuaca Hujan", 26}
  , Sign{"I-1aa", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan yang Ditegaskan Penjelasan Jenis Peringatan dengan Menggunakan Papan Tambahan", 27}
  , Sign{"I-1ab", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pekerjaan di Jalan", 28}
  , Sign{"I-1ac", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pengaturan Lalu Lintas oleh Petugas; Peringatan Pelaksanaan Inspeksi di Jalan; Peringatan Pelaksanaan Survey di Jalan", 29}
  , Sign{"I-4a", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Berjalan Terus karena Wajib Berhenti Sesaat dan/atau Melanjutkan Perjalanan Setelah Dipastikan Selamat dari Konflik Lalu Lintas dari Arah Lainnya", 30}
  , Sign{"I-4b", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Berjalan Terus Sebelum Melaksanakan Kegiatan Tertentu, Contoh: Larangan Melanjutkan Perjalanan Sebelum Membayar Tarif Tol", 31}
  , Sign{"I-4c", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dan Tidak Bermotor", 32}
  , Sign{"I-4d", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Sepeda Motor", 33}
  , Sign{"I-4e", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor Roda Tiga", 34}
  , Sign{"I-4f", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Mobil Penumpang Perseorangan", 35}
  , Sign{"I-4g", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Mobil Barang", 36}
  , Sign{"I-4h", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor Umum", 37}
  , Sign{"I-4i", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Kereta Tempel", 38}
  , Sign{"I-4j", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Berat Keseluruhan Sama atau Lebih dari 5 ton", 39}
  , Sign{"I-4k", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Beban Sumbu Sama atau Lebih dari 8 ton", 40}
  , Sign{"I-4l", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Mendekati Kendaraan di Depan dengan Jarak Sama atau Kurang dari ... m", 41}
  , Sign{"I-4m", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Menjalankan Kendaraan dengan Kecepatan Lebih dari 40 km/jam", 42}
  , Sign{"I-4n", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Batas Akhir Seluruh Larangan yang Dinyatakan oleh Satu atau Lebih Rambu Larangan", 43}
  , Sign{"I-7a", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Mengikuti ke Arah Kiri", 44}
  , Sign{"I-7b", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Mengikuti ke Arah Kanan", 45}
  , Sign{"I-7c", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Belok ke Arah Kiri", 46}
  , Sign{"I-7d", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Belok ke Arah Kanan", 47}
  , Sign{"I-7e", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Berjalan Lurus", 48}
  , Sign{"I-7f", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Memilih Lurus atau Belok Kiri", 49}
  , Sign{"I-7g", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Memilih Lurus atau Belok Kanan", 50}
  , Sign{"I-7h", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Memasuki Jalur atau Lajur yang Ditunjuk", 51}
  , Sign{"I-7i", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Memasuki Jalur atau Lajur yang Ditunjuk", 52}
  , Sign{"I-7j", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Pilihan Memasuki Salah Satu Jalur atau Lajur yang Ditunjuk", 53}
  , Sign{"I-7k", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Kecepatan Minimum yang Diperintahkan, Contoh: 40 km/jam", 54}
  , Sign{"I-7l", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Rantai Khusus Ban", 55}
  , Sign{"I-7m", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Sepeda Motor", 56}
  , Sign{"I-7n", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Bermotor Umum", 57}
  , Sign{"I-7o", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Mobil Barang", 58}
  , Sign{"I-7p", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Pejalan Kaki", 59}
  , Sign{"I-7q", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Sepeda", 60}
  , Sign{"I-7r", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Delman", 61}
  , Sign{"I-10a", Elektronik{}, "Piktogram Rambu Petunjuk", M.Guidance{}, "Pendahulu Petunjuk Jurusan pada Persimpangan di Depan", 62}
  , Sign{"I-10b", Elektronik{}, "Piktogram Rambu Petunjuk", M.Guidance{}, "Rute Perjalanan", 63}
  , Sign{"I-10c", Elektronik{}, "Piktogram Rambu Petunjuk", M.Guidance{}, "Pendahulu Petunjuk Jurusan yang Menunjukkan Jurusan yang Dituju", 64}
  , Sign{"II-1a", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan ke Kiri", 65}
  , Sign{"II-1b", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan ke Kanan", 66}
  , Sign{"II-1c", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Ganda dengan Tikungan Pertama ke Kiri", 67}
  , Sign{"II-1d", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Ganda dengan Tikungan Pertama ke Kanan", 68}
  , Sign{"II-1e", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Tajam ke Kiri", 69}
  , Sign{"II-1f", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Tajam ke Kanan", 70}
  , Sign{"II-1g", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Tajam Ganda dengan Tikungan Pertama ke Kiri", 71}
  , Sign{"II-1h", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Tajam Ganda dengan Tikungan Pertama ke Kanan", 72}
  , Sign{"II-1i", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Banyak Tikungan dengan Tikungan Pertama ke Kiri", 73}
  , Sign{"II-1j", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Banyak Tikungan dengan Tikungan Pertama ke Kanan", 74}
  , Sign{"II-1k", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Memutar ke Kiri", 75}
  , Sign{"II-1l", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Memutar ke Kanan", 76}
  , Sign{"II-1m", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kiri dan Kanan", 77}
  , Sign{"II-1n", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kiri dan Kanan", 78}
  , Sign{"II-1o", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kiri", 79}
  , Sign{"II-1p", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kanan", 80}
  , Sign{"II-1q", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kiri", 81}
  , Sign{"II-1r", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kanan", 82}
  , Sign{"II-1s", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pengurangan Lajur Kiri", 83}
  , Sign{"II-1t", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pengurangan Lajur Kanan", 84}
  , Sign{"II-1u", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penambahan Lajur Kiri", 85}
  , Sign{"II-1v", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penambahan Lajur Kanan", 86}
  , Sign{"II-1w", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Jembatan; Peringatan Penyempitan Bagan Jalinan Jalan Tertentu", 87}
  , Sign{"II-2a", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Vertikal", M.Warning{}, "Peringatan Turunan Landai", 88}
  , Sign{"II-2b", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Vertikal", M.Warning{}, "Peringatan Turunan Curam", 89}
  , Sign{"II-2c", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Vertikal", M.Warning{}, "Peringatan Tanjakan Landai", 90}
  , Sign{"II-2d", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Vertikal", M.Warning{}, "Peringatan Tanjakan Curam", 91}
  , Sign{"II-3a", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Permukaan Jalan yang Licin", 92}
  , Sign{"II-3b", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Bagian Tepi Jalan yang Tidak Sama Tinggi dengan Badan Jalan", 93}
  , Sign{"II-3c", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Jurang", 94}
  , Sign{"II-3d", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Tepi Air", 95}
  , Sign{"II-3e", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Permukaan Jalan yang Cekung atau Berlubang", 96}
  , Sign{"II-3f", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Permukaan Jalan yang Cembung; Peringatan Alat Pembatas Kecepatan", 97}
  , Sign{"II-3g", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Jalan Bergelombang", 98}
  , Sign{"II-3h", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Lontaran Kerikil", 99}
  , Sign{"II-3i", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Bagian Tepi Jalan Sebelah Kiri yang Rawan Runtuh", 100}
  , Sign{"II-3j", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Bagian Tepi Jalan Sebelah Kanan yang Rawan Runtuh", 101}
  , Sign{"II-4a1", Peringatan{}, "Rambu Peringatan Pengaturan Persinyalan", M.Warning{}, "Peringatan Alat Pemberi Isyarat Lalu Lintas", 102}
  , Sign{"II-4a2", Peringatan{}, "Rambu Peringatan Pengaturan Persinyalan", M.Warning{}, "Peringatan Lampu Isyarat Penyeberang Jalan", 103}
  , Sign{"II-4b1", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Simpang Empat Prioritas (Ditempatkan pada Lengan Minor)", 104}
  , Sign{"II-4b2", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Simpang Empat Prioritas (Ditempatkan pada Lengan Mayor)", 105}
  , Sign{"II-4b3", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Bundaran dengan Prioritas", 106}
  , Sign{"II-4b4", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Serong Kiri (Ditempatkan pada Lengan Minor)", 107}
  , Sign{"II-4b5", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Serong Kanan (Ditempatkan pada Lengan Minor)", 108}
  , Sign{"II-4b6", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Serong Kiri (Ditempatkan pada Lengan Mayor)", 109}
  , Sign{"II-4b7", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Serong Kanan (Ditempatkan pada Lengan Mayor)", 110}
  , Sign{"II-4b8", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Sisi Kiri (Ditempatkan pada Lengan Minor)", 111}
  , Sign{"II-4b9", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Sisi Kanan (Ditempatkan pada Lengan Minor)", 112}
  , Sign{"II-4b10", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Berganda Sisi Kiri dan Kanan (Ditempatkan pada Lengan Mayor)", 113}
  , Sign{"II-4b11", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Berganda Sisi Kanan dan Kiri (Ditempatkan pada Lengan Mayor)", 114}
  , Sign{"II-4b12", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Serong Kiri", 115}
  , Sign{"II-4b13", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Serong Kanan", 116}
  , Sign{"II-4b14", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Berganda Sisi Kiri (Ditempatkan pada Lengan Mayor)", 117}
  , Sign{"II-4b15", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Berganda Sisi Kanan (Ditempatkan pada Lengan Mayor)", 118}
  , Sign{"II-4b16", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Sisi Kiri (Ditempatkan pada Lengan Mayor)", 119}
  , Sign{"II-4b17", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Sisi Kanan (Ditempatkan pada Lengan Mayor)", 120}
  , Sign{"II-4b18", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Tipe T (Ditempatkan pada Lengan Minor)", 121}
  , Sign{"II-4b19", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Tipe Y", 122}
  , Sign{"II-4c1", Peringatan{}, "Rambu Peringatan Konstruksi Pemisah Jalur Lalu Lintas", M.Warning{}, "Peringatan Awal Pembatas Konstruksi Fisik Pemisah Jalur Lalu Lintas Dua Arah", 123}
  , Sign{"II-4c2", Peringatan{}, "Rambu Peringatan Konstruksi Pemisah Jalur Lalu Lintas", M.Warning{}, "Peringatan Akhir Pembatas Konstruksi Fisik Pemisah Jalur Lalu Lintas Dua Arah", 124}
  , Sign{"II-4c3", Peringatan{}, "Rambu Peringatan Konstruksi Pemisah Jalur Lalu Lintas", M.Warning{}, "Peringatan Awal Pembatas Konstruksi Fisik Pemisah Jalur Lalu Lintas Satu Arah; Peringatan Awal Pembatas Konstruksi Fisik Pemisah Lajur Lalu Lintas", 125}
  , Sign{"II-4c4", Peringatan{}, "Rambu Peringatan Konstruksi Pemisah Jalur Lalu Lintas", M.Warning{}, "Peringatan Akhir Pembatas Konstruksi Fisik Pemisah Jalur Lalu Lintas Satu Arah; Peringatan Akhir Pembatas Konstruksi Fisik Pemisah Lajur Lalu Lintas", 126}
  , Sign{"II-5a", Peringatan{}, "Rambu Peringatan Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Angkutan Barang", 127}
  , Sign{"II-5b", Peringatan{}, "Rambu Peringatan Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Angkutan Barang Tipe Curah/Cair", 128}
  , Sign{"II-5c", Peringatan{}, "Rambu Peringatan Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Angkutan Barang Berbahaya dan Beracun", 129}
  , Sign{"II-5d", Peringatan{}, "Rambu Peringatan Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Angkutan Barang Mudah Terbakar", 130}
  , Sign{"II-5e", Peringatan{}, "Rambu Peringatan Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Angkutan Umum", 131}
  , Sign{"II-5f", Peringatan{}, "Rambu Peringatan Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Kendaraan Berat", 132}
  , Sign{"II-6a", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Pejalan Kaki Menggunakan Fasilitas Penyeberangan", 133}
  , Sign{"II-6b", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Pejalan Kaki", 134}
  , Sign{"II-6c", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Pejalan Kaki Anak-anak", 135}
  , Sign{"II-6d", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Penyandang Cacat", 136}
  , Sign{"II-6e", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Sepeda", 137}
  , Sign{"II-6f", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Hewan Ternak Melintas", 138}
  , Sign{"II-6g", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Hewan Liar Melintas", 139}
  , Sign{"II-7a", Peringatan{}, "Rambu Peringatan Kawasan Rawan Bencana", M.Warning{}, "Peringatan Kawasan Rawan Bencana Tsunami", 140}
  , Sign{"II-7b", Peringatan{}, "Rambu Peringatan Kawasan Rawan Bencana", M.Warning{}, "Peringatan Kawasan Rawan Bencana Gempa Bumi", 141}
  , Sign{"II-7c", Peringatan{}, "Rambu Peringatan Kawasan Rawan Bencana", M.Warning{}, "Peringatan Kawasan Rawan Bencana Gunung Api", 142}
  , Sign{"II-8a", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan yang Ditegaskan Penjelasan Jenis Peringatan dengan Menggunakan Papan Tambahan", 143}
  , Sign{"II-8b", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Pekerjaan di Jalan", 144}
  , Sign{"II-8c", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Tinggi Ruang Bebas (... m)", 145}
  , Sign{"II-8d", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Lebar Ruang Bebas (... m)", 146}
  , Sign{"II-8e", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Pintu Perlintasan Sebidang Kereta Api", 147}
  , Sign{"II-8f", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Perlintasan Sebidang Kereta Api tanpa Pintu", 148}
  , Sign{"II-8g", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Lalu Lintas Pesawat Terbang yang Terbang Rendah", 149}
  , Sign{"II-8h", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Hembusan Angin Kencang", 150}
  , Sign{"II-8i", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Lalu Lintas Dua Arah", 151}
  , Sign{"II-8j", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Jembatan Angkat", 152}
  , Sign{"II-10a", Peringatan{}, "Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis", M.Warning{}, "Peringatan yang Menerangkan bahwa Lokasi Kritis Berjarak 450 m dari Lokasi Rambu", 153}
  , Sign{"II-10b", Peringatan{}, "Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis", M.Warning{}, "Peringatan yang Menerangkan bahwa Lokasi Kritis Berjarak 300 m dari Lokasi Rambu", 154}
  , Sign{"II-10c", Peringatan{}, "Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis", M.Warning{}, "Peringatan yang Menerangkan bahwa Lokasi Kritis Berjarak 150 m dari Lokasi Rambu", 155}
  , Sign{"II-11a", Peringatan{}, "Rambu Peringatan Pengarah Gerakan Lalu Lintas", M.Warning{}, "Peringatan Rintangan atau Objek Berbahaya pada Sisi Jalan Sebelah Kiri (Hanya Dapat Melakukan Gerakan Lalu Lintas pada Sisi Sebelah Kanan)", 156}
  , Sign{"II-11b", Peringatan{}, "Rambu Peringatan Pengarah Gerakan Lalu Lintas", M.Warning{}, "Peringatan Rintangan atau Objek Berbahaya pada Sisi Jalan Sebelah Kanan (Hanya Dapat Melakukan Gerakan Lalu Lintas pada Sisi Sebelah Kiri)", 157}
  , Sign{"II-11c", Peringatan{}, "Rambu Peringatan Pengarah Gerakan Lalu Lintas", M.Warning{}, "Peringatan Rintangan atau Objek Berbahaya pada Pemisah Lajur atau Jalur (Dapat Melakukan Gerakan Lalu Lintas pada Kedua Sisi)", 158}
  , Sign{"II-11d", Peringatan{}, "Rambu Peringatan Pengarah Gerakan Lalu Lintas", M.Warning{}, "Pengarah Tikungan ke Kiri", 159}
  , Sign{"II-11e", Peringatan{}, "Rambu Peringatan Pengarah Gerakan Lalu Lintas", M.Warning{}, "Pengarah Tikungan ke Kanan", 160}
  , Sign{"III-1a", Larangan{}, "Rambu Larangan Berjalan Terus", M.Prohibition{}, "Larangan Berjalan Terus karena Wajib Berhenti Sesaat dan/atau Melanjutkan Perjalanan Setelah Dipastikan Selamat dari Konflik Lalu Lintas dari Arah Lainnya", 161}
  , Sign{"III-1b", Larangan{}, "Rambu Larangan Berjalan Terus", M.Prohibition{}, "Larangan Berjalan Terus karena Wajib Memberi Prioritas kepada Arus Lalu Lintas dari Arah yang Diberi Prioritas", 162}
  , Sign{"III-1c", Larangan{}, "Rambu Larangan Berjalan Terus", M.Prohibition{}, "Larangan Berjalan Terus Sebelum Melaksanakan Kegiatan Tertentu, Contoh: Larangan Melanjutkan Perjalanan Sebelum Membayar Tarif Tol", 163}
  , Sign{"III-1d", Larangan{}, "Rambu Larangan Berjalan Terus", M.Prohibition{}, "Larangan Berjalan Terus pada Bagian Jalan Tertentu Sebelum Mendahulukan Arus Lalu Lintas yang Datang dari Arah Berlawanan", 164}
  , Sign{"III-1e", Larangan{}, "Rambu Larangan Berjalan Terus", M.Prohibition{}, "Larangan Berjalan Terus pada Perlintasan Sebidang Lintasan Kereta Api Jalur Tunggal Sebelum Mendapatkan Kepastian Selamat dari Konflik", 165}
  , Sign{"III-1f", Larangan{}, "Rambu Larangan Berjalan Terus", M.Prohibition{}, "Larangan Berjalan Terus pada Perlintasan Sebidang Lintasan Kereta Api Jalur Ganda Sebelum Mendapatkan Kepastian Selamat dari Konflik", 166}
  , Sign{"III-2a1", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor dan Tidak Bermotor", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dan Tidak Bermotor dari Kedua Arah", 167}
  , Sign{"III-2a2", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor dan Tidak Bermotor", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dan Tidak Bermotor", 168}
  , Sign{"III-2b1", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Sepeda Motor", 169}
  , Sign{"III-2b2", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor Roda Tiga", 170}
  , Sign{"III-2b3", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Mobil Penumpang", 171}
  , Sign{"III-2b4", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Mobil Barang", 172}
  , Sign{"III-2b5", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Mobil Bus", 173}
  , Sign{"III-2b6", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Khusus", 174}
  , Sign{"III-2b7", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Kereta Tempel", 175}
  , Sign{"III-2b8", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Kereta Gandeng", 176}
  , Sign{"III-2b9", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Sepeda Motor dan Mobil Penumpang", 177}
  , Sign{"III-2b10", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Mobil Penumpang Perseorangan dan Mobil Barang", 178}
  , Sign{"III-2b11", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Mobil Barang dan Kendaraan Bermotor Umum", 179}
  , Sign{"III-2b12", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Sepeda Motor, Mobil Penumpang Perseorangan dan Mobil Barang", 180}
  , Sign{"III-2b13", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Mobil Penumpang Perseorangan, Mobil Barang dan Kendaraan Bermotor Umum", 181}
  , Sign{"III-2c1", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Pejalan Kaki", 182}
  , Sign{"III-2c2", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Gerobak Dorong dan Sejenisnya", 183}
  , Sign{"III-2c3", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Sepeda", 184}
  , Sign{"III-2c4", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Becak", 185}
  , Sign{"III-2c5", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Pedati", 186}
  , Sign{"III-2c6", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Delman/Dokar", 187}
  , Sign{"III-2c7", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Sepeda dan Becak", 188}
  , Sign{"III-2c8", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Delman dan Pedati", 189}
  , Sign{"III-2c9", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Semua Jenis Kendaraan Tidak Bermotor", 190}
  , Sign{"III-2d1", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Panjang Lebih dari ... m", 191}
  , Sign{"III-2d2", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Tinggi Lebih dari ... m", 192}
  , Sign{"III-2d3", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Lebar Lebih dari ... m", 193}
  , Sign{"III-2d4", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Tidak Bermotor dengan Panjang Lebih dari ... m", 194}
  , Sign{"III-2d5", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Jumlah Berat yang Diizinkan (JBI) Sama atau Lebih dari 5 ton", 195}
  , Sign{"III-2d6", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor Roda Tunggal dengan Muatan Sumbu Terberat (MST) Sama atau Lebih dari 8 ton", 196}
  , Sign{"III-2d7", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor Roda Ganda atau Lebih dengan Muatan Sumbu Terberat (MST) Sama atau Lebih dari 8 ton", 197}
  , Sign{"III-2d8", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Roda Tunggal pada Ujung Sumbu dengan Berat Muatan Sama atau Lebih dari 8 ton", 198}
  , Sign{"III-2d9", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Roda Ganda atau Lebih pada Ujung Sumbu dengan Berat Muatan Sama atau Lebih dari 8 ton", 199}
  , Sign{"III-2d10", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan dengan Ukuran Lebar Melebihi 2.500 Milimeter, Ukuran Panjang Melebihi 18.000 Milimeter, Ukuran Paling Tinggi 4.200 Milimeter, dan Muatan Sumbu Terberat 10 ton", 200}
  , Sign{"III-2d11", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan dengan Ukuran Lebar Melebihi 2.500 Milimeter, Ukuran Panjang Melebihi 12.000 Milimeter, Ukuran Paling Tinggi 4.200 Milimeter, dan Muatan Sumbu Terberat 8 ton", 201}
  , Sign{"III-2d12", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan dengan Ukuran Lebar Melebihi 2.100 Milimeter, Ukuran Panjang Melebihi 9.000 Milimeter, Ukuran Paling Tinggi 3.500 Milimeter, dan Muatan Sumbu Terberat 8 ton", 202}
  , Sign{"III-3a", Larangan{}, "Rambu Larangan Parkir dan Berhenti", M.Prohibition{}, "Larangan Berhenti", 203}
  , Sign{"III-3b", Larangan{}, "Rambu Larangan Parkir dan Berhenti", M.Prohibition{}, "Larangan Parkir", 204}
  , Sign{"III-4a", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Berjalan Terus", 205}
  , Sign{"III-4b", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Belok Kiri", 206}
  , Sign{"III-4c", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Belok Kanan", 207}
  , Sign{"III-4d", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Menyalip Kendaraan Lain", 208}
  , Sign{"III-4e", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Memutar Balik", 209}
  , Sign{"III-4f", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Memutar Balik dan Belok Kanan", 210}
  , Sign{"III-4g", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Mendekati Kendaraan di Depan dengan Jarak Sama atau Kurang dari ... m", 211}
  , Sign{"III-4h", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Menjalankan Kendaraan dengan Kecepatan Lebih dari yang Tertulis, Contoh: Kecepatan Maksimum Kendaraan yang Dilarang adalah 50 km/jam", 212}
  , Sign{"IV-1a", Perintah{}, "Rambu Perintah Mematuhi Arah yang Ditunjuk", M.Command{}, "Perintah Mengikuti ke Arah Kiri", 213}
  , Sign{"IV-1b", Perintah{}, "Rambu Perintah Mematuhi Arah yang Ditunjuk", M.Command{}, "Perintah Mengikuti ke Arah Kanan", 214}
  , Sign{"IV-1c", Perintah{}, "Rambu Perintah Mematuhi Arah yang Ditunjuk", M.Command{}, "Perintah Belok ke Arah Kiri", 215}
  , Sign{"IV-1d", Perintah{}, "Rambu Perintah Mematuhi Arah yang Ditunjuk", M.Command{}, "Perintah Belok ke Arah Kanan", 216}
  , Sign{"IV-1e", Perintah{}, "Rambu Perintah Mematuhi Arah yang Ditunjuk", M.Command{}, "Perintah Berjalan Lurus", 217}
  , Sign{"IV-1f", Perintah{}, "Rambu Perintah Mematuhi Arah yang Ditunjuk", M.Command{}, "Perintah Mengikuti Arah yang Ditunjukkan saat Memasuki Bundaran", 218}
  , Sign{"IV-2a", Perintah{}, "Rambu Perintah Memilih Salah Satu Arah yang Ditunjuk", M.Command{}, "Perintah Memilih Lurus atau Belok Kiri", 219}
  , Sign{"IV-2b", Perintah{}, "Rambu Perintah Memilih Salah Satu Arah yang Ditunjuk", M.Command{}, "Perintah Memilih Lurus atau Belok Kanan", 220}
  , Sign{"IV-3a", Perintah{}, "Rambu Perintah Memasuki Bagian Jalan Tertentu", M.Command{}, "Perintah Memasuki Jalur atau Lajur yang Ditunjuk", 221}
  , Sign{"IV-3b", Perintah{}, "Rambu Perintah Memasuki Bagian Jalan Tertentu", M.Command{}, "Perintah Memasuki Jalur atau Lajur yang Ditunjuk", 222}
  , Sign{"IV-3c", Perintah{}, "Rambu Perintah Memasuki Bagian Jalan Tertentu", M.Command{}, "Perintah Pilihan Memasuki Salah Satu Jalur atau Lajur yang Ditunjuk", 223}
  , Sign{"IV-4", Perintah{}, "Rambu Perintah Batas Minimum Kecepatan", M.Command{}, "Kecepatan Minimum yang Diperintahkan, Contoh: 50 km/jam", 224}
  , Sign{"IV-5", Perintah{}, "Rambu Perintah Penggunaan Rantai Ban", M.Command{}, "Perintah Menggunakan Rantai Khusus Ban", 225}
  , Sign{"IV-6a1", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Sepeda Motor", 226}
  , Sign{"IV-6a2", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Mobil Bus", 227}
  , Sign{"IV-6a3", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Mobil Barang", 228}
  , Sign{"IV-6b1", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Pejalan Kaki", 229}
  , Sign{"IV-6b2", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Penunggang Kuda", 230}
  , Sign{"IV-6b3", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Sepeda", 231}
  , Sign{"IV-6b4", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Becak", 232}
  , Sign{"IV-6b5", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Pedati", 233}
  , Sign{"IV-6b6", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Delman", 234}
  , Sign{"IV-6b7", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", 235}
  , Sign{"IV-7a", Perintah{}, "Rambu Batas Akhir Perintah Tertentu", M.Command{}, "Batas Akhir Kecepatan Minimum yang Diperintahkan", 236}
  , Sign{"IV-7b", Perintah{}, "Rambu Batas Akhir Perintah Tertentu", M.Command{}, "Batas Akhir Perintah Menggunakan Rantai Khusus Ban", 237}
  , Sign{"V-1a", Petunjuk{}, "Rambu Petunjuk Pendahulu Jurusan", M.Guidance{}, "Pendahulu Petunjuk Jurusan pada Persimpangan di Depan", 238}
  , Sign{"V-1b", Petunjuk{}, "Rambu Petunjuk Pendahulu Jurusan", M.Guidance{}, "Pendahulu Petunjuk Jurusan yang Menunjukkan Jurusan yang Dituju", 239}
  , Sign{"V-1c", Petunjuk{}, "Rambu Petunjuk Pendahulu Jurusan", M.Guidance{}, "Pendahulu Petunjuk Jurusan yang Menunjukkan Jalur atau Lajur untuk Mencapai Jurusan yang Dituju pada Pintu Keluar Jalan Tol", 240}
  , Sign{"V-1d", Petunjuk{}, "Rambu Petunjuk Pendahulu Jurusan", M.Guidance{}, "Pendahulu Petunjuk Jurusan yang Menunjukkan Jalur atau Lajur Sebelah Kiri untuk Mencapai Jurusan yang Dituju", 241}
  , Sign{"V-1e", Petunjuk{}, "Rambu Petunjuk Pendahulu Jurusan", M.Guidance{}, "Pendahulu Petunjuk Jurusan yang Menunjukkan Jalur atau Lajur Sebelah Kanan untuk Mencapai Jurusan yang Dituju", 242}
  , Sign{"V-1f", Petunjuk{}, "Rambu Petunjuk Pendahulu Jurusan", M.Guidance{}, "Pendahulu Petunjuk Jurusan yang Menunjukkan Jarak Jurusan yang Dituju", 243}
  , Sign{"V-3a", Petunjuk{}, "Rambu Petunjuk Batas Wilayah", M.Guidance{}, "Rambu Petunjuk Batas Awal Wilayah (Contoh: Kabupaten Toli-Toli)", 244}
  , Sign{"V-3b", Petunjuk{}, "Rambu Petunjuk Batas Wilayah", M.Guidance{}, "Rambu Petunjuk Batas Akhir Wilayah (Contoh: Kabupaten Toli-Toli)", 245}
  , Sign{"V-4a", Petunjuk{}, "Rambu Petunjuk Batas Jalan Tol", M.Guidance{}, "Rambu Petunjuk Batas Awal Jalan Tol", 246}
  , Sign{"V-4b", Petunjuk{}, "Rambu Petunjuk Batas Jalan Tol", M.Guidance{}, "Rambu Petunjuk Batas Akhir Jalan Tol", 247}
  , Sign{"V-4c", Petunjuk{}, "Rambu Petunjuk Batas Jalan Tol", M.Guidance{}, "Rambu Petunjuk Batas Awal Jalan Tol Lingkar Dalam", 248}
  , Sign{"V-4d", Petunjuk{}, "Rambu Petunjuk Batas Jalan Tol", M.Guidance{}, "Rambu Petunjuk Batas Akhir Jalan Tol Lingkar Dalam", 249}
  , Sign{"V-5a1", Petunjuk{}, "Rambu Petunjuk Lokasi Simpul Transportasi", M.Guidance{}, "Petunjuk Lokasi Terminal Kendaraan Bermotor Umum", 250}
  , Sign{"V-5a2", Petunjuk{}, "Rambu Petunjuk Lokasi Simpul Transportasi", M.Guidance{}, "Petunjuk Lokasi Stasiun Kereta Api", 251}
  , Sign{"V-5a3", Petunjuk{}, "Rambu Petunjuk Lokasi Simpul Transportasi", M.Guidance{}, "Petunjuk Lokasi Pelabuhan", 252}
  , Sign{"V-5a4", Petunjuk{}, "Rambu Petunjuk Lokasi Simpul Transportasi", M.Guidance{}, "Petunjuk Lokasi Bandar Udara", 253}
  , Sign{"V-5b1", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Kebersihan", M.Guidance{}, "Petunjuk Lokasi Tempat Penampungan Sampah", 254}
  , Sign{"V-5b2", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Kebersihan", M.Guidance{}, "Petunjuk Lokasi Tempat Pembuangan Sampah", 255}
  , Sign{"V-5c1", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Komunikasi", M.Guidance{}, "Petunjuk Lokasi Kantor Pos", 256}
  , Sign{"V-5c2", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Komunikasi", M.Guidance{}, "Petunjuk Lokasi Telepon Umum", 257}
  , Sign{"V-5d1", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Pemberhentian Angkutan Umum", M.Guidance{}, "Petunjuk Lokasi Fasilitas Pemberhentian Mobil Bus Umum", 258}
  , Sign{"V-5d2", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Pemberhentian Angkutan Umum", M.Guidance{}, "Petunjuk Lokasi Fasilitas Pangkalan Taksi", 259}
  , Sign{"V-5d3", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Pemberhentian Angkutan Umum", M.Guidance{}, "Petunjuk Lokasi Fasilitas Pemberhentian dan/atau Pangkalan Angkutan Umum Selain Mobil Bus Umum dan Taksi", 260}
  , Sign{"V-5f1", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Parkir", M.Guidance{}, "Petunjuk Lokasi Fasilitas Parkir", 261}
  , Sign{"V-5f2", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Parkir", M.Guidance{}, "Petunjuk Lokasi Fasilitas Parkir Tertentu, Contoh: Petunjuk Lokasi Fasilitas Parkir Penyandang Cacat", 262}
  , Sign{"V-5g1", Petunjuk{}, "Rambu Petunjuk Terowongan", M.Guidance{}, "Petunjuk Awal Terowongan", 263}
  , Sign{"V-5g2", Petunjuk{}, "Rambu Petunjuk Terowongan", M.Guidance{}, "Petunjuk Akhir Terowongan", 264}
  , Sign{"V-5h1", Petunjuk{}, "Rambu Petunjuk Fasilitas Tanggap Bencana", M.Guidance{}, "Petunjuk Jalur Evakuasi Tsunami", 265}
  , Sign{"V-5h2", Petunjuk{}, "Rambu Petunjuk Fasilitas Tanggap Bencana", M.Guidance{}, "Petunjuk Jalur Evakuasi Gempa Bumi", 266}
  , Sign{"V-5h3", Petunjuk{}, "Rambu Petunjuk Fasilitas Tanggap Bencana", M.Guidance{}, "Petunjuk Jalur Evakuasi Gunung Meletus", 267}
  , Sign{"V-5h4", Petunjuk{}, "Rambu Petunjuk Fasilitas Tanggap Bencana", M.Guidance{}, "Petunjuk Lokasi Tempat Berkumpul Darurat", 268}
  , Sign{"V-5h5", Petunjuk{}, "Rambu Petunjuk Fasilitas Tanggap Bencana", M.Guidance{}, "Petunjuk Lokasi Tempat Kemah Pengungsian", 269}
  , Sign{"V-5h6", Petunjuk{}, "Rambu Petunjuk Fasilitas Tanggap Bencana", M.Guidance{}, "Petunjuk Lokasi Bangunan Pengungsian", 270}
  , Sign{"V-6a1", Petunjuk{}, "Rambu Petunjuk Lokasi Peribadatan", M.Guidance{}, "Petunjuk Lokasi Masjid", 271}
  , Sign{"V-6a2", Petunjuk{}, "Rambu Petunjuk Lokasi Peribadatan", M.Guidance{}, "Petunjuk Lokasi Gereja", 272}
  , Sign{"V-6a3", Petunjuk{}, "Rambu Petunjuk Lokasi Peribadatan", M.Guidance{}, "Petunjuk Lokasi Wihara", 273}
  , Sign{"V-6a4", Petunjuk{}, "Rambu Petunjuk Lokasi Peribadatan", M.Guidance{}, "Petunjuk Lokasi Pura", 274}
  , Sign{"V-6b1", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Rumah Sakit", 275}
  , Sign{"V-6b2", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Balai Kesehatan, Puskesmas, Balai Pertolongan Pertama dan yang Sejenis", 276}
  , Sign{"V-6b3", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Apotek", 277}
  , Sign{"V-6b4", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi SPBU", 278}
  , Sign{"V-6b5", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Unit Pelaksana Pengujian Berkala Kendaraan Bermotor", 279}
  , Sign{"V-6b6", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Unit Pelaksana Pengujian dan/atau Pemeriksaan Salah Satu Unsur Laik Jalan Kendaraan Bermotor, Contoh: Pemeriksaan Emisi Kendaraan Bermotor", 280}
  , Sign{"V-6b7", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Unit Pelaksana Penimbangan Kendaraan Bermotor", 281}
  , Sign{"V-6b8", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Museum", 282}
  , Sign{"V-6c1", Petunjuk{}, "Rambu Petunjuk Lokasi Perbelanjaan dan Niaga", M.Guidance{}, "Petunjuk Lokasi Pusat Perbelanjaan dan Pasar", 283}
  , Sign{"V-6c2", Petunjuk{}, "Rambu Petunjuk Lokasi Perbelanjaan dan Niaga", M.Guidance{}, "Petunjuk Lokasi Rumah Makan", 284}
  , Sign{"V-6c3", Petunjuk{}, "Rambu Petunjuk Lokasi Perbelanjaan dan Niaga", M.Guidance{}, "Petunjuk Lokasi Tempat Penjualan Minuman", 285}
  , Sign{"V-6c4", Petunjuk{}, "Rambu Petunjuk Lokasi Perbelanjaan dan Niaga", M.Guidance{}, "Petunjuk Lokasi Penginapan", 286}
  , Sign{"V-6c5", Petunjuk{}, "Rambu Petunjuk Lokasi Perbelanjaan dan Niaga", M.Guidance{}, "Petunjuk Lokasi Bengkel Kendaraan Bermotor", 287}
  , Sign{"V-6d1", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Taman", 288}
  , Sign{"V-6d2", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Rute Lintas Alam", 289}
  , Sign{"V-6d3", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Perkemahan", 290}
  , Sign{"V-6d4", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Perkemahan Menggunakan Kereta Kemah", 291}
  , Sign{"V-6d5", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Perkemahan dan Perkemahan Menggunakan Kereta Kemah", 292}
  , Sign{"V-6d6", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Vila", 293}
  , Sign{"V-6d7", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Pantai", 294}
  , Sign{"V-6e1", Petunjuk{}, "Rambu Petunjuk Lokasi Sarana Olahraga dan Lapangan Terbuka", M.Guidance{}, "Petunjuk Lokasi Lapangan Terbuka", 295}
  , Sign{"V-6e2", Petunjuk{}, "Rambu Petunjuk Lokasi Sarana Olahraga dan Lapangan Terbuka", M.Guidance{}, "Petunjuk Lokasi Gedung Olah Raga", 296}
  , Sign{"V-6e3", Petunjuk{}, "Rambu Petunjuk Lokasi Sarana Olahraga dan Lapangan Terbuka", M.Guidance{}, "Petunjuk Lokasi Kolam Renang", 297}
  , Sign{"V-6e4", Petunjuk{}, "Rambu Petunjuk Lokasi Sarana Olahraga dan Lapangan Terbuka", M.Guidance{}, "Petunjuk Lokasi Stadium Olah Raga", 298}
  , Sign{"V-6f1", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Pendidikan", M.Guidance{}, "Petunjuk Lokasi Sekolah", 299}
  , Sign{"V-6f2", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Pendidikan", M.Guidance{}, "Petunjuk Lokasi Perpustakaan", 300}
  , Sign{"V-7a", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Sistem Satu Arah", 301}
  , Sign{"V-7b", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Sistem Satu Arah ke Kiri", 302}
  , Sign{"V-7c", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Sistem Satu Arah ke Kanan", 303}
  , Sign{"V-7d", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Jalan Buntu di Depan", 304}
  , Sign{"V-7e", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Jalan Buntu pada Belokan Sebelah Kanan", 305}
  , Sign{"V-7f", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Mendapatkan Prioritas Melanjutkan Perjalanan dari Arah Berlawanan", 306}
  , Sign{"V-7g", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Lokasi Putar Balik", 307}
  , Sign{"V-7h", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Awal Bagian Jalan untuk Kendaraan Bermotor", 308}
  , Sign{"V-7i", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Akhir Bagian Jalan untuk Kendaraan Bermotor", 309}
  , Sign{"V-10a", Petunjuk{}, "Bentuk Nomor Rute", M.Guidance{}, "Menyatakan Nomor Rute Asian Highway", 310}
  , Sign{"V-10b", Petunjuk{}, "Bentuk Nomor Rute", M.Guidance{}, "Menyatakan Nomor Rute Jalan Nasional", 311}
  , Sign{"V-10c", Petunjuk{}, "Bentuk Nomor Rute", M.Guidance{}, "Menyatakan Nomor Rute Jalan Provinsi", 312}
  , Sign{"V-10d", Petunjuk{}, "Bentuk Nomor Rute", M.Guidance{}, "Menyatakan Nomor Rute Jalan Kabupaten", 313}
  , Sign{"V-10e", Petunjuk{}, "Bentuk Nomor Rute", M.Guidance{}, "Menyatakan Nomor Rute Jalan Kota", 314}
  , Sign{"VI-1a", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Gerakan Belok Kiri", 315}
  , Sign{"VI-1b", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Gerakan Belok Kanan", 316}
  , Sign{"VI-1c", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kiri dan Kanan", 317}
  , Sign{"VI-1d", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kiri dan Kanan", 318}
  , Sign{"VI-1e", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kiri", 319}
  , Sign{"VI-1f", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kanan", 320}
  , Sign{"VI-1g", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kiri", 321}
  , Sign{"VI-1h", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kanan", 322}
  , Sign{"VI-1i", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pengurangan Lajur Kiri", 323}
  , Sign{"VI-1j", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pengurangan Lajur Kanan", 324}
  , Sign{"VI-1k", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penambahan Lajur Kiri", 325}
  , Sign{"VI-1l", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penambahan Lajur Kanan", 326}
  , Sign{"VI-1m", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Bagan Jalinan Jalan Tertentu", 327}
  , Sign{"VI-2a", PeringatanSementara{}, "Rambu Peringatan Sementara Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Permukaan Jalan yang Licin", 328}
  , Sign{"VI-2b", PeringatanSementara{}, "Rambu Peringatan Sementara Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Bagian Tepi Jalan yang Tidak Sama Tinggi dengan Badan Jalan", 329}
  , Sign{"VI-2c", PeringatanSementara{}, "Rambu Peringatan Sementara Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Lontaran Kerikil", 330}
  , Sign{"VI-3a", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Awal Rintangan pada Sisi Kiri Jalan", 331}
  , Sign{"VI-3b", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Awal Rintangan pada Sisi Kanan Jalan", 332}
  , Sign{"VI-3c", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Akhir Rintangan pada Sisi Kiri Jalan", 333}
  , Sign{"VI-3d", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Akhir Rintangan pada Sisi Kanan Jalan", 334}
  , Sign{"VI-3e", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Awal Rintangan yang Memisahkan Lajur", 335}
  , Sign{"VI-3f", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Akhir Rintangan yang Memisahkan Lajur", 336}
  , Sign{"VI-3g", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Awal Rintangan yang Memisahkan Jalur", 337}
  , Sign{"VI-3h", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Akhir Rintangan yang Memisahkan Jalur", 338}
  , Sign{"VI-4a", PeringatanSementara{}, "Rambu Peringatan Sementara Lainnya", M.Warning{}, "Peringatan yang Ditegaskan Penjelasan Jenis Peringatan dengan Menggunakan Papan Tambahan", 339}
  , Sign{"VI-4b", PeringatanSementara{}, "Rambu Peringatan Sementara Lainnya", M.Warning{}, "Peringatan Pekerjaan di Jalan", 340}
  , Sign{"VI-4c", PeringatanSementara{}, "Rambu Peringatan Sementara Lainnya", M.Warning{}, "Peringatan Tinggi Ruang Bebas (... m)", 341}
  , Sign{"VI-4d", PeringatanSementara{}, "Rambu Peringatan Sementara Lainnya", M.Warning{}, "Peringatan Lebar Ruang Bebas (... m)", 342}
  , Sign{"VI-4e", PeringatanSementara{}, "Rambu Peringatan Sementara Lainnya", M.Warning{}, "Peringatan Lalu Lintas Dua Arah", 343}
  , Sign{"VI-4f", PeringatanSementara{}, "Rambu Peringatan Sementara Lainnya", M.Warning{}, "Peringatan Pengaturan Lalu Lintas oleh Petugas; Peringatan Pelaksanaan Inspeksi di Jalan; Peringatan Pelaksanaan Survey di Jalan", 344}
  , Sign{"VI-6a", PeringatanSementara{}, "Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis Sementara", M.Warning{}, "Peringatan yang Menerangkan bahwa Lokasi Kritis Berjarak 450 m dari Lokasi Rambu", 345}
  , Sign{"VI-6b", PeringatanSementara{}, "Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis Sementara", M.Warning{}, "Peringatan yang Menerangkan bahwa Lokasi Kritis Berjarak 300 m dari Lokasi Rambu", 346}
  , Sign{"VI-6c", PeringatanSementara{}, "Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis Sementara", M.Warning{}, "Peringatan yang Menerangkan bahwa Lokasi Kritis Berjarak 150 m dari Lokasi Rambu", 347}
  ]

def supplements() -> List<&2, Supplement>:
  [
    Supplement{"Papan Tambahan Nilai Tertentu", "Papan Tambahan yang Menambahkan Penjelasan Nilai Tertentu ke Dalam Arti Rambu", 1}
  , Supplement{"Papan Tambahan Arah Tertentu", "Papan Tambahan yang Menambahkan Penjelasan Arah Tertentu ke Dalam Arti Rambu", 2}
  , Supplement{"Papan Tambahan Arah dan Nilai Tertentu", "Papan Tambahan yang Menambahkan Penjelasan Arah dan Nilai Tertentu ke Dalam Arti Rambu", 3}
  , Supplement{"Papan Tambahan Hal Tertentu dengan Kata-kata", "Papan Tambahan yang Menambahkan Penjelasan Hal-Hal Tertentu dengan Kata-kata", 4}
  , Supplement{"Papan Tambahan Hal Tertentu dengan Kata-kata dan Nilai", "Papan Tambahan yang Menambahkan Penjelasan Hal-Hal Tertentu dengan Kata-kata dan Nilai", 5}
  ]

def groups() -> List<&2, Group>:
  [
    Group{"Piktogram Rambu Peringatan", Elektronik{}, 29}
  , Group{"Pesan Peringatan", Elektronik{}, 0}
  , Group{"Piktogram Rambu Peringatan dan Pesan Peringatan", Elektronik{}, 0}
  , Group{"Piktogram Rambu Larangan", Elektronik{}, 14}
  , Group{"Pesan Larangan", Elektronik{}, 0}
  , Group{"Piktogram Rambu Larangan dan Pesan Larangan", Elektronik{}, 0}
  , Group{"Piktogram Rambu Perintah", Elektronik{}, 18}
  , Group{"Pesan Perintah", Elektronik{}, 0}
  , Group{"Piktogram Rambu Perintah dan Pesan Perintah", Elektronik{}, 0}
  , Group{"Piktogram Rambu Petunjuk", Elektronik{}, 3}
  , Group{"Pesan Petunjuk", Elektronik{}, 0}
  , Group{"Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", Peringatan{}, 23}
  , Group{"Rambu Peringatan Perubahan Kondisi Alinyemen Vertikal", Peringatan{}, 4}
  , Group{"Rambu Peringatan Kondisi Jalan yang Berbahaya", Peringatan{}, 10}
  , Group{"Rambu Peringatan Pengaturan Persinyalan", Peringatan{}, 2}
  , Group{"Rambu Peringatan Persimpangan Prioritas", Peringatan{}, 19}
  , Group{"Rambu Peringatan Konstruksi Pemisah Jalur Lalu Lintas", Peringatan{}, 4}
  , Group{"Rambu Peringatan Lalu Lintas Kendaraan Bermotor", Peringatan{}, 6}
  , Group{"Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", Peringatan{}, 7}
  , Group{"Rambu Peringatan Kawasan Rawan Bencana", Peringatan{}, 3}
  , Group{"Rambu Peringatan Lainnya", Peringatan{}, 10}
  , Group{"Rambu Peringatan dengan Kata-kata", Peringatan{}, 0}
  , Group{"Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis", Peringatan{}, 3}
  , Group{"Rambu Peringatan Pengarah Gerakan Lalu Lintas", Peringatan{}, 5}
  , Group{"Rambu Larangan Berjalan Terus", Larangan{}, 6}
  , Group{"Rambu Larangan Masuk bagi Kendaraan Bermotor dan Tidak Bermotor", Larangan{}, 2}
  , Group{"Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", Larangan{}, 13}
  , Group{"Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", Larangan{}, 9}
  , Group{"Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", Larangan{}, 12}
  , Group{"Rambu Larangan Parkir dan Berhenti", Larangan{}, 2}
  , Group{"Rambu Larangan Pergerakan Lalu Lintas Tertentu", Larangan{}, 8}
  , Group{"Rambu Larangan Membunyikan Isyarat Suara", Larangan{}, 0}
  , Group{"Rambu Larangan dengan Kata-kata", Larangan{}, 0}
  , Group{"Rambu Batas Akhir Larangan", Larangan{}, 0}
  , Group{"Rambu Perintah Mematuhi Arah yang Ditunjuk", Perintah{}, 6}
  , Group{"Rambu Perintah Memilih Salah Satu Arah yang Ditunjuk", Perintah{}, 2}
  , Group{"Rambu Perintah Memasuki Bagian Jalan Tertentu", Perintah{}, 3}
  , Group{"Rambu Perintah Batas Minimum Kecepatan", Perintah{}, 1}
  , Group{"Rambu Perintah Penggunaan Rantai Ban", Perintah{}, 1}
  , Group{"Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Bermotor", Perintah{}, 3}
  , Group{"Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", Perintah{}, 7}
  , Group{"Rambu Batas Akhir Perintah Tertentu", Perintah{}, 2}
  , Group{"Rambu Perintah dengan Kata-kata", Perintah{}, 0}
  , Group{"Rambu Petunjuk Pendahulu Jurusan", Petunjuk{}, 6}
  , Group{"Rambu Petunjuk Jurusan Wilayah dan Lokasi Tertentu", Petunjuk{}, 0}
  , Group{"Rambu Petunjuk Jurusan Khusus Lokasi dan Kawasan Wisata", Petunjuk{}, 0}
  , Group{"Rambu Petunjuk Batas Wilayah", Petunjuk{}, 2}
  , Group{"Rambu Petunjuk Batas Jalan Tol", Petunjuk{}, 4}
  , Group{"Rambu Petunjuk Lokasi Simpul Transportasi", Petunjuk{}, 4}
  , Group{"Rambu Petunjuk Lokasi Fasilitas Kebersihan", Petunjuk{}, 2}
  , Group{"Rambu Petunjuk Lokasi Fasilitas Komunikasi", Petunjuk{}, 2}
  , Group{"Rambu Petunjuk Lokasi Fasilitas Pemberhentian Angkutan Umum", Petunjuk{}, 3}
  , Group{"Rambu Petunjuk Lokasi Fasilitas Penyeberangan Pejalan Kaki", Petunjuk{}, 0}
  , Group{"Rambu Petunjuk Lokasi Fasilitas Parkir", Petunjuk{}, 2}
  , Group{"Rambu Petunjuk Terowongan", Petunjuk{}, 2}
  , Group{"Rambu Petunjuk Fasilitas Tanggap Bencana", Petunjuk{}, 6}
  , Group{"Rambu Petunjuk Lokasi Peribadatan", Petunjuk{}, 4}
  , Group{"Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", Petunjuk{}, 8}
  , Group{"Rambu Petunjuk Lokasi Perbelanjaan dan Niaga", Petunjuk{}, 5}
  , Group{"Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", Petunjuk{}, 7}
  , Group{"Rambu Petunjuk Lokasi Sarana Olahraga dan Lapangan Terbuka", Petunjuk{}, 4}
  , Group{"Rambu Petunjuk Lokasi Fasilitas Pendidikan", Petunjuk{}, 2}
  , Group{"Rambu Petunjuk Pengaturan Lalu Lintas", Petunjuk{}, 9}
  , Group{"Papan Nama Jalan", Petunjuk{}, 0}
  , Group{"Rambu Petunjuk dengan Kata-kata", Petunjuk{}, 0}
  , Group{"Bentuk Nomor Rute", Petunjuk{}, 5}
  , Group{"Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", PeringatanSementara{}, 13}
  , Group{"Rambu Peringatan Sementara Kondisi Jalan yang Berbahaya", PeringatanSementara{}, 3}
  , Group{"Rambu Peringatan Sementara Rintangan di Jalan", PeringatanSementara{}, 8}
  , Group{"Rambu Peringatan Sementara Lainnya", PeringatanSementara{}, 6}
  , Group{"Rambu Peringatan Sementara dengan Kata-kata", PeringatanSementara{}, 0}
  , Group{"Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis Sementara", PeringatanSementara{}, 3}
  ]


# UU 22/2009 Pasal 106 ayat (4) huruf a binds a driver to a command or a
# prohibition. A warning names a hazard and a guidance sign gives information;
# neither states a duty a moment can break.
def binds_driver(f: M.Sign) -> Bool:
  match f:
    case M.Warning{}:
      False{}
    case M.Prohibition{}:
      True{}
    case M.Command{}:
      True{}
    case M.Guidance{}:
      False{}

# ---------------------------------------------------------------------------
# The operative rule each sign posts
#
# A prohibition or command sign posts a duty, not a sentence. The duty is what
# the adjudicator applies: a NoStopping duty charges a driver who stops, a
# NoLeftTurn duty charges a driver who turns left. A warning or guidance sign
# posts no duty, so it has no entry here.
# ---------------------------------------------------------------------------

type SignRule is Data:
  SignRule{code: String, duty: M.Duty}

def rules() -> List<&2, SignRule>:
  [
    SignRule{"I-4a", M.Stop{}}
  , SignRule{"I-4b", M.Stop{}}
  , SignRule{"I-4c", M.NoEntry{[M.Any{}]}}
  , SignRule{"I-4d", M.NoEntry{[M.Motorcycle{}]}}
  , SignRule{"I-4e", M.NoEntry{[M.ThreeWheel{}]}}
  , SignRule{"I-4f", M.NoEntry{[M.Car{}]}}
  , SignRule{"I-4g", M.NoEntry{[M.Truck{}]}}
  , SignRule{"I-4h", M.NoEntry{[M.Public{}]}}
  , SignRule{"I-4i", M.NoEntry{[M.Trailer{}]}}
  , SignRule{"I-4j", M.WeightLimit{5}}
  , SignRule{"I-4k", M.AxleLimit{8}}
  , SignRule{"I-4l", M.NoCloseFollowing{0}}
  , SignRule{"I-4m", M.MaxSpeed{40}}
  , SignRule{"I-4n", M.EndOfRestriction{}}
  , SignRule{"I-7a", M.KeepLeft{}}
  , SignRule{"I-7b", M.KeepRight{}}
  , SignRule{"I-7c", M.TurnLeft{}}
  , SignRule{"I-7d", M.TurnRight{}}
  , SignRule{"I-7e", M.GoStraight{}}
  , SignRule{"I-7f", M.ChoosePath{}}
  , SignRule{"I-7g", M.ChoosePath{}}
  , SignRule{"I-7h", M.UseLane{M.Any{}}}
  , SignRule{"I-7i", M.UseLane{M.Any{}}}
  , SignRule{"I-7j", M.UseLane{M.Any{}}}
  , SignRule{"I-7k", M.MinSpeed{40}}
  , SignRule{"I-7l", M.UseChains{}}
  , SignRule{"I-7m", M.UseLane{M.Motorcycle{}}}
  , SignRule{"I-7n", M.UseLane{M.Public{}}}
  , SignRule{"I-7o", M.UseLane{M.Truck{}}}
  , SignRule{"I-7p", M.UseLane{M.Pedestrian{}}}
  , SignRule{"I-7q", M.UseLane{M.Bicycle{}}}
  , SignRule{"I-7r", M.UseLane{M.Delman{}}}
  , SignRule{"III-1a", M.Stop{}}
  , SignRule{"III-1b", M.GiveWay{}}
  , SignRule{"III-1c", M.Stop{}}
  , SignRule{"III-1d", M.GiveWay{}}
  , SignRule{"III-1e", M.Stop{}}
  , SignRule{"III-1f", M.Stop{}}
  , SignRule{"III-2a1", M.NoEntry{[M.Any{}]}}
  , SignRule{"III-2a2", M.NoEntry{[M.Any{}]}}
  , SignRule{"III-2b1", M.NoEntry{[M.Motorcycle{}]}}
  , SignRule{"III-2b2", M.NoEntry{[M.ThreeWheel{}]}}
  , SignRule{"III-2b3", M.NoEntry{[M.Car{}]}}
  , SignRule{"III-2b4", M.NoEntry{[M.Truck{}]}}
  , SignRule{"III-2b5", M.NoEntry{[M.Bus{}]}}
  , SignRule{"III-2b6", M.NoEntry{[M.Special{}]}}
  , SignRule{"III-2b7", M.NoEntry{[M.Trailer{}]}}
  , SignRule{"III-2b8", M.NoEntry{[M.Trailer{}]}}
  , SignRule{"III-2b9", M.NoEntry{[M.Motorcycle{}, M.Car{}]}}
  , SignRule{"III-2b10", M.NoEntry{[M.Car{}, M.Truck{}]}}
  , SignRule{"III-2b11", M.NoEntry{[M.Truck{}, M.Public{}]}}
  , SignRule{"III-2b12", M.NoEntry{[M.Motorcycle{}, M.Car{}, M.Truck{}]}}
  , SignRule{"III-2b13", M.NoEntry{[M.Car{}, M.Truck{}, M.Public{}]}}
  , SignRule{"III-2c1", M.NoEntry{[M.Pedestrian{}]}}
  , SignRule{"III-2c2", M.NoEntry{[M.Cart{}]}}
  , SignRule{"III-2c3", M.NoEntry{[M.Bicycle{}]}}
  , SignRule{"III-2c4", M.NoEntry{[M.Becak{}]}}
  , SignRule{"III-2c5", M.NoEntry{[M.Pedati{}]}}
  , SignRule{"III-2c6", M.NoEntry{[M.Delman{}]}}
  , SignRule{"III-2c7", M.NoEntry{[M.Bicycle{}, M.Becak{}]}}
  , SignRule{"III-2c8", M.NoEntry{[M.Delman{}, M.Pedati{}]}}
  , SignRule{"III-2c9", M.NoEntry{[M.NonMotorized{}]}}
  , SignRule{"III-2d1", M.LengthLimit{0}}
  , SignRule{"III-2d2", M.HeightLimit{0}}
  , SignRule{"III-2d3", M.WidthLimit{0}}
  , SignRule{"III-2d4", M.LengthLimit{0}}
  , SignRule{"III-2d5", M.WeightLimit{5}}
  , SignRule{"III-2d6", M.AxleLimit{8}}
  , SignRule{"III-2d7", M.AxleLimit{8}}
  , SignRule{"III-2d8", M.AxleLimit{8}}
  , SignRule{"III-2d9", M.AxleLimit{8}}
  , SignRule{"III-2d10", M.DimensionLimit{2500, 18000, 4200, 10}}
  , SignRule{"III-2d11", M.DimensionLimit{2500, 12000, 4200, 8}}
  , SignRule{"III-2d12", M.DimensionLimit{2100, 9000, 3500, 8}}
  , SignRule{"III-3a", M.NoStopping{}}
  , SignRule{"III-3b", M.NoParking{}}
  , SignRule{"III-4a", M.Stop{}}
  , SignRule{"III-4b", M.NoLeftTurn{}}
  , SignRule{"III-4c", M.NoRightTurn{}}
  , SignRule{"III-4d", M.NoOvertaking{}}
  , SignRule{"III-4e", M.NoUTurn{}}
  , SignRule{"III-4f", M.NoUTurnOrRight{}}
  , SignRule{"III-4g", M.NoCloseFollowing{0}}
  , SignRule{"III-4h", M.MaxSpeed{50}}
  , SignRule{"IV-1a", M.KeepLeft{}}
  , SignRule{"IV-1b", M.KeepRight{}}
  , SignRule{"IV-1c", M.TurnLeft{}}
  , SignRule{"IV-1d", M.TurnRight{}}
  , SignRule{"IV-1e", M.GoStraight{}}
  , SignRule{"IV-1f", M.Roundabout{}}
  , SignRule{"IV-2a", M.ChoosePath{}}
  , SignRule{"IV-2b", M.ChoosePath{}}
  , SignRule{"IV-3a", M.UseLane{M.Any{}}}
  , SignRule{"IV-3b", M.UseLane{M.Any{}}}
  , SignRule{"IV-3c", M.UseLane{M.Any{}}}
  , SignRule{"IV-4", M.MinSpeed{50}}
  , SignRule{"IV-5", M.UseChains{}}
  , SignRule{"IV-6a1", M.UseLane{M.Motorcycle{}}}
  , SignRule{"IV-6a2", M.UseLane{M.Bus{}}}
  , SignRule{"IV-6a3", M.UseLane{M.Truck{}}}
  , SignRule{"IV-6b1", M.UseLane{M.Pedestrian{}}}
  , SignRule{"IV-6b2", M.UseLane{M.HorseRider{}}}
  , SignRule{"IV-6b3", M.UseLane{M.Bicycle{}}}
  , SignRule{"IV-6b4", M.UseLane{M.Becak{}}}
  , SignRule{"IV-6b5", M.UseLane{M.Pedati{}}}
  , SignRule{"IV-6b6", M.UseLane{M.Delman{}}}
  , SignRule{"IV-6b7", M.UseLane{M.NonMotorized{}}}
  , SignRule{"IV-7a", M.EndOfRestriction{}}
  , SignRule{"IV-7b", M.EndOfRestriction{}}
  ]

def choose_duty(same: Bool, +found: M.Duty, fallback: M.Duty) -> M.Duty:
  match same:
    case True{}:
      found
    case False{}:
      fallback

# A sign with no entry posts no duty.
def duty_of(+code: String, xs: List<&2, SignRule>) -> M.Duty:
  match xs:
    case Nil{}:
      M.NoDuty{}
    case h <> tl:
      match h:
        case SignRule{+hc, +duty}:
          choose_duty(String.eq(code, hc), duty, duty_of(code, tl))

# The duty a game posts when it places a sign with this code.
def posted(+code: String) -> M.Duty:
  duty_of(code, rules())

def count_rules(xs: List<&2, SignRule>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_rules(t))

def rule_count() -> U32:
  count_rules(rules())

# ---------------------------------------------------------------------------
# Reading a duty
# ---------------------------------------------------------------------------

def is_no_duty(d: M.Duty) -> Bool:
  match d:
    case M.NoDuty{}:
      True{}
    case _:
      False{}

def is_no_stopping(d: M.Duty) -> Bool:
  match d:
    case M.NoStopping{}:
      True{}
    case _:
      False{}

def is_no_parking(d: M.Duty) -> Bool:
  match d:
    case M.NoParking{}:
      True{}
    case _:
      False{}

def is_no_left_turn(d: M.Duty) -> Bool:
  match d:
    case M.NoLeftTurn{}:
      True{}
    case _:
      False{}

def is_stop(d: M.Duty) -> Bool:
  match d:
    case M.Stop{}:
      True{}
    case _:
      False{}

def is_give_way(d: M.Duty) -> Bool:
  match d:
    case M.GiveWay{}:
      True{}
    case _:
      False{}

def is_keep_left(d: M.Duty) -> Bool:
  match d:
    case M.KeepLeft{}:
      True{}
    case _:
      False{}

def is_no_entry(d: M.Duty) -> Bool:
  match d:
    case M.NoEntry{subjects}:
      True{}
    case _:
      False{}

def duty_tag(d: M.Duty) -> U32:
  match d:
    case M.NoDuty{}:
      0
    case M.Stop{}:
      1
    case M.GiveWay{}:
      2
    case M.NoEntry{subjects}:
      3
    case M.NoStopping{}:
      4
    case M.NoParking{}:
      5
    case M.NoLeftTurn{}:
      6
    case M.NoRightTurn{}:
      7
    case M.NoUTurn{}:
      8
    case M.NoUTurnOrRight{}:
      9
    case M.NoOvertaking{}:
      10
    case M.NoCloseFollowing{metres}:
      11
    case M.MaxSpeed{limit}:
      12
    case M.MinSpeed{limit}:
      13
    case M.KeepLeft{}:
      14
    case M.KeepRight{}:
      15
    case M.TurnLeft{}:
      16
    case M.TurnRight{}:
      17
    case M.GoStraight{}:
      18
    case M.ChoosePath{}:
      19
    case M.Roundabout{}:
      20
    case M.UseLane{subject}:
      21
    case M.UseChains{}:
      22
    case M.WeightLimit{limit}:
      23
    case M.AxleLimit{limit}:
      24
    case M.LengthLimit{limit}:
      25
    case M.HeightLimit{limit}:
      26
    case M.WidthLimit{limit}:
      27
    case M.DimensionLimit{width, length, height, axle}:
      28
    case M.EndOfRestriction{}:
      29

def same_duty_kind(a: M.Duty, b: M.Duty) -> Bool:
  U32.is_eq(duty_tag(a), duty_tag(b))

def max_speed_limit(d: M.Duty) -> U32:
  match d:
    case M.MaxSpeed{limit}:
      limit
    case _:
      0

def min_speed_limit(d: M.Duty) -> U32:
  match d:
    case M.MinSpeed{limit}:
      limit
    case _:
      0

# ---------------------------------------------------------------------------
# Completeness of the rule table
# ---------------------------------------------------------------------------

def has_code(+c: String, xs: List<&2, Sign>) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case h <> tl:
      match h:
        case Sign{+hc, table, group, family, meaning, ordinal}:
          Bool.or(String.eq(c, hc), has_code(c, tl))

def rule_exists(+c: String, xs: List<&2, SignRule>) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case h <> tl:
      match h:
        case SignRule{+hc, duty}:
          Bool.or(String.eq(c, hc), rule_exists(c, tl))

def rule_code_is(+c: String, r: SignRule) -> Bool:
  match r:
    case SignRule{+hc, duty}:
      String.eq(c, hc)

def rule_dup_go(+c: String, xs: List<&2, SignRule>) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case h <> tl:
      Bool.or(rule_code_is(c, h), rule_dup_go(c, tl))

def rule_dup_step(r: SignRule, +tl: List<&2, SignRule>, rest: Bool) -> Bool:
  match r:
    case SignRule{+hc, duty}:
      Bool.or(rule_dup_go(hc, tl), rest)

def has_duplicate_rule(xs: List<&2, SignRule>) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case h <> +tl:
      rule_dup_step(h, tl, has_duplicate_rule(tl))

def rule_codes_unique(xs: List<&2, SignRule>) -> Bool:
  Bool.not(has_duplicate_rule(xs))

def rules_catalogued(rs: List<&2, SignRule>, +signs: List<&2, Sign>) -> Bool:
  match rs:
    case Nil{}:
      True{}
    case h <> tl:
      match h:
        case SignRule{+code, duty}:
          Bool.and(has_code(code, signs), rules_catalogued(tl, signs))

def binding_rule_if(binds: Bool, +code: String, +rs: List<&2, SignRule>) -> Bool:
  match binds:
    case True{}:
      Bool.not(is_no_duty(duty_of(code, rs)))
    case False{}:
      is_no_duty(duty_of(code, rs))

def binding_rules_ok(xs: List<&2, Sign>, +rs: List<&2, SignRule>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> tl:
      match h:
        case Sign{+code, table, group, +family, meaning, ordinal}:
          Bool.and(binding_rule_if(binds_driver(family), code, rs), binding_rules_ok(tl, rs))

# ---------------------------------------------------------------------------
# Counting and checking
# ---------------------------------------------------------------------------

def count_signs(xs: List<&2, Sign>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_signs(t))

def count_supplements(xs: List<&2, Supplement>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_supplements(t))

def count_groups(xs: List<&2, Group>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> t:
      U32.add(1, count_groups(t))

def same_table(a: Table, b: Table) -> Bool:
  match a:
    case Elektronik{}:
      match b:
        case Elektronik{}:
          True{}
        case _:
          False{}
    case Peringatan{}:
      match b:
        case Peringatan{}:
          True{}
        case _:
          False{}
    case Larangan{}:
      match b:
        case Larangan{}:
          True{}
        case _:
          False{}
    case Perintah{}:
      match b:
        case Perintah{}:
          True{}
        case _:
          False{}
    case Petunjuk{}:
      match b:
        case Petunjuk{}:
          True{}
        case _:
          False{}
    case PeringatanSementara{}:
      match b:
        case PeringatanSementara{}:
          True{}
        case _:
          False{}
    case PapanTambahan{}:
      match b:
        case PapanTambahan{}:
          True{}
        case _:
          False{}

def same_family(a: M.Sign, b: M.Sign) -> Bool:
  match a:
    case M.Warning{}:
      match b:
        case M.Warning{}:
          True{}
        case _:
          False{}
    case M.Prohibition{}:
      match b:
        case M.Prohibition{}:
          True{}
        case _:
          False{}
    case M.Command{}:
      match b:
        case M.Command{}:
          True{}
        case _:
          False{}
    case M.Guidance{}:
      match b:
        case M.Guidance{}:
          True{}
        case _:
          False{}

# A table count adds one for each entry whose table matches.
def count_table(+t: Table, xs: List<&2, Sign>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> tl:
      match h:
        case Sign{code, table, group, family, meaning, ordinal}:
          U32.add(Bool.to_u32(same_table(t, table)), count_table(t, tl))

def count_family(+f: M.Sign, xs: List<&2, Sign>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> tl:
      match h:
        case Sign{code, table, group, family, meaning, ordinal}:
          U32.add(Bool.to_u32(same_family(f, family)), count_family(f, tl))

def count_group(+g: String, xs: List<&2, Sign>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> tl:
      match h:
        case Sign{code, table, +group, family, meaning, ordinal}:
          U32.add(Bool.to_u32(String.eq(g, group)), count_group(g, tl))

# Ordinals run 1, 2, 3 ... without a gap, in catalogue order.
def numbered(xs: List<&2, Sign>, +expected: U32) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> tl:
      match h:
        case Sign{code, table, group, family, meaning, ordinal}:
          Bool.and(U32.is_eq(ordinal, expected), numbered(tl, U32.add(expected, 1)))

def all_meaningful(xs: List<&2, Sign>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> tl:
      match h:
        case Sign{code, table, group, family, meaning, ordinal}:
          Bool.and(Bool.not(String.is_empty(meaning)), all_meaningful(tl))

def table_family_ok(t: Table, f: M.Sign) -> Bool:
  match t:
    case Elektronik{}:
      True{}
    case Peringatan{}:
      same_family(f, M.Warning{})
    case Larangan{}:
      same_family(f, M.Prohibition{})
    case Perintah{}:
      same_family(f, M.Command{})
    case Petunjuk{}:
      same_family(f, M.Guidance{})
    case PeringatanSementara{}:
      same_family(f, M.Warning{})
    case PapanTambahan{}:
      False{}

def all_family_ok(xs: List<&2, Sign>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> tl:
      match h:
        case Sign{code, +table, group, +family, meaning, ordinal}:
          Bool.and(table_family_ok(table, family), all_family_ok(tl))

def code_is(+c: String, s: Sign) -> Bool:
  match s:
    case Sign{+hc, table, group, family, meaning, ordinal}:
      String.eq(c, hc)

def dup_go(+c: String, xs: List<&2, Sign>) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case h <> tl:
      Bool.or(code_is(c, h), dup_go(c, tl))

def dup_step(h: Sign, +tl: List<&2, Sign>, rest: Bool) -> Bool:
  match h:
    case Sign{+hc, table, group, family, meaning, ordinal}:
      Bool.or(dup_go(hc, tl), rest)

def has_duplicate(xs: List<&2, Sign>) -> Bool:
  match xs:
    case Nil{}:
      False{}
    case h <> +tl:
      dup_step(h, tl, has_duplicate(tl))

def no_duplicate_codes(xs: List<&2, Sign>) -> Bool:
  Bool.not(has_duplicate(xs))

def groups_sized(gs: List<&2, Group>, +xs: List<&2, Sign>) -> Bool:
  match gs:
    case Nil{}:
      True{}
    case g <> gt:
      match g:
        case Group{+name, table, size}:
          Bool.and(U32.is_eq(count_group(name, xs), size), groups_sized(gt, xs))

def supplements_numbered(xs: List<&2, Supplement>, +expected: U32) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> tl:
      match h:
        case Supplement{group, meaning, ordinal}:
          Bool.and(U32.is_eq(ordinal, expected), supplements_numbered(tl, U32.add(expected, 1)))

# ---------------------------------------------------------------------------
# The tables, and the totals the regulation states
# ---------------------------------------------------------------------------

def table_size(t: Table) -> U32:
  match t:
    case Elektronik{}:
      64
    case Peringatan{}:
      96
    case Larangan{}:
      52
    case Perintah{}:
      25
    case Petunjuk{}:
      77
    case PeringatanSementara{}:
      33
    case PapanTambahan{}:
      0

def sign_count() -> U32:
  count_signs(signs())

def supplement_count() -> U32:
  count_supplements(supplements())

def group_count() -> U32:
  count_groups(groups())

def conventional_count() -> U32:
  U32.add(count_table(Peringatan{}, signs()),
  U32.add(count_table(Larangan{}, signs()),
  U32.add(count_table(Perintah{}, signs()),
  U32.add(count_table(Petunjuk{}, signs()), count_table(PeringatanSementara{}, signs())))))

def warning_count() -> U32:
  count_family(M.Warning{}, signs())

def prohibition_count() -> U32:
  count_family(M.Prohibition{}, signs())

def command_count() -> U32:
  count_family(M.Command{}, signs())

def guidance_count() -> U32:
  count_family(M.Guidance{}, signs())

