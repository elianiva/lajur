# lajur — the sign catalogue: every rambu PM 13/2014 lists, table by table.
#
# The regulation enumerates signs by a code inside each Lampiran table, so a
# code alone is ambiguous: 1a is a warning sign in Tabel II and a piktogram in
# Tabel I. The catalogue keys each sign by table and code, written "II-1a".
# The code after the dash is the regulation's own code, unchanged. A code that
# the table gives two names carries both, separated by "; ".
#
# `duty` is the operative rule the sign posts. A warning or guidance sign
# carries NoDuty. A prohibition or command sign carries the rule the
# adjudicator applies: NoStopping charges a driver who stops, NoLeftTurn a
# driver who turns left.
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
  Sign{code: String, table: Table, group: String, family: M.Sign, meaning: String, duty: M.Duty, ordinal: U32}

type Group is Data:
  Group{name: String, table: Table, size: U32}

type Supplement is Data:
  Supplement{group: String, meaning: String, ordinal: U32}

# ---------------------------------------------------------------------------
# The catalogue
# ---------------------------------------------------------------------------

def signs() -> List<&2, Sign>:
  [
    Sign{"I-1a", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kiri dan Kanan", M.NoDuty{}, 1}
  , Sign{"I-1b", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kiri dan Kanan", M.NoDuty{}, 2}
  , Sign{"I-1c", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kiri", M.NoDuty{}, 3}
  , Sign{"I-1d", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kanan", M.NoDuty{}, 4}
  , Sign{"I-1e", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kiri", M.NoDuty{}, 5}
  , Sign{"I-1f", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kanan", M.NoDuty{}, 6}
  , Sign{"I-1g", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pengurangan Lajur Kiri", M.NoDuty{}, 7}
  , Sign{"I-1h", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pengurangan Lajur Kanan", M.NoDuty{}, 8}
  , Sign{"I-1i", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Penambahan Lajur Kiri", M.NoDuty{}, 9}
  , Sign{"I-1j", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Penambahan Lajur Kanan", M.NoDuty{}, 10}
  , Sign{"I-1k", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Jembatan; Peringatan Penyempitan Bagan Jalinan Jalan Tertentu", M.NoDuty{}, 11}
  , Sign{"I-1l", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Permukaan Jalan yang Licin", M.NoDuty{}, 12}
  , Sign{"I-1m", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Lontaran Kerikil", M.NoDuty{}, 13}
  , Sign{"I-1n", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Telah Terjadi Longsor pada Sebelah Kiri Sisi Jalan", M.NoDuty{}, 14}
  , Sign{"I-1o", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Telah Terjadi Longsor pada Sebelah Kanan Sisi Jalan", M.NoDuty{}, 15}
  , Sign{"I-1p", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Banyak Lalu Lintas Pejalan Kaki", M.NoDuty{}, 16}
  , Sign{"I-1q", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Banyak Lalu Lintas Pejalan Kaki Anak-anak", M.NoDuty{}, 17}
  , Sign{"I-1r", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Banyak Lalu Lintas Penyandang Cacat", M.NoDuty{}, 18}
  , Sign{"I-1s", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Banyak Lalu Lintas Sepeda", M.NoDuty{}, 19}
  , Sign{"I-1t", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Banyak Hewan Ternak Melintas", M.NoDuty{}, 20}
  , Sign{"I-1u", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Banyak Hewan Liar Melintas", M.NoDuty{}, 21}
  , Sign{"I-1v", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Kondisi Lalu Lintas Padat", M.NoDuty{}, 22}
  , Sign{"I-1w", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Kecelakaan Tunggal", M.NoDuty{}, 23}
  , Sign{"I-1x", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Kecelakaan Ganda", M.NoDuty{}, 24}
  , Sign{"I-1y", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Kondisi Cuaca Berkabut", M.NoDuty{}, 25}
  , Sign{"I-1z", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Kondisi Cuaca Hujan", M.NoDuty{}, 26}
  , Sign{"I-1aa", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan yang Ditegaskan Penjelasan Jenis Peringatan dengan Menggunakan Papan Tambahan", M.NoDuty{}, 27}
  , Sign{"I-1ab", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pekerjaan di Jalan", M.NoDuty{}, 28}
  , Sign{"I-1ac", Elektronik{}, "Piktogram Rambu Peringatan", M.Warning{}, "Peringatan Pengaturan Lalu Lintas oleh Petugas; Peringatan Pelaksanaan Inspeksi di Jalan; Peringatan Pelaksanaan Survey di Jalan", M.NoDuty{}, 29}
  , Sign{"I-4a", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Berjalan Terus karena Wajib Berhenti Sesaat dan/atau Melanjutkan Perjalanan Setelah Dipastikan Selamat dari Konflik Lalu Lintas dari Arah Lainnya", M.Stop{}, 30}
  , Sign{"I-4b", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Berjalan Terus Sebelum Melaksanakan Kegiatan Tertentu, Contoh: Larangan Melanjutkan Perjalanan Sebelum Membayar Tarif Tol", M.Stop{}, 31}
  , Sign{"I-4c", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dan Tidak Bermotor", M.NoEntry{[M.Any{}]}, 32}
  , Sign{"I-4d", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Sepeda Motor", M.NoEntry{[M.Motorcycle{}]}, 33}
  , Sign{"I-4e", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor Roda Tiga", M.NoEntry{[M.ThreeWheel{}]}, 34}
  , Sign{"I-4f", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Mobil Penumpang Perseorangan", M.NoEntry{[M.Car{}]}, 35}
  , Sign{"I-4g", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Mobil Barang", M.NoEntry{[M.Truck{}]}, 36}
  , Sign{"I-4h", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor Umum", M.NoEntry{[M.Public{}]}, 37}
  , Sign{"I-4i", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Kereta Tempel", M.NoEntry{[M.Trailer{}]}, 38}
  , Sign{"I-4j", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Berat Keseluruhan Sama atau Lebih dari 5 ton", M.WeightLimit{5}, 39}
  , Sign{"I-4k", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Beban Sumbu Sama atau Lebih dari 8 ton", M.AxleLimit{8}, 40}
  , Sign{"I-4l", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Mendekati Kendaraan di Depan dengan Jarak Sama atau Kurang dari ... m", M.NoCloseFollowing{0}, 41}
  , Sign{"I-4m", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Larangan Menjalankan Kendaraan dengan Kecepatan Lebih dari 40 km/jam", M.MaxSpeed{40}, 42}
  , Sign{"I-4n", Elektronik{}, "Piktogram Rambu Larangan", M.Prohibition{}, "Batas Akhir Seluruh Larangan yang Dinyatakan oleh Satu atau Lebih Rambu Larangan", M.EndOfRestriction{}, 43}
  , Sign{"I-7a", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Mengikuti ke Arah Kiri", M.KeepLeft{}, 44}
  , Sign{"I-7b", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Mengikuti ke Arah Kanan", M.KeepRight{}, 45}
  , Sign{"I-7c", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Belok ke Arah Kiri", M.TurnLeft{}, 46}
  , Sign{"I-7d", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Belok ke Arah Kanan", M.TurnRight{}, 47}
  , Sign{"I-7e", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Berjalan Lurus", M.GoStraight{}, 48}
  , Sign{"I-7f", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Memilih Lurus atau Belok Kiri", M.ChoosePath{}, 49}
  , Sign{"I-7g", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Memilih Lurus atau Belok Kanan", M.ChoosePath{}, 50}
  , Sign{"I-7h", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Memasuki Jalur atau Lajur yang Ditunjuk", M.UseLane{M.Any{}}, 51}
  , Sign{"I-7i", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Memasuki Jalur atau Lajur yang Ditunjuk", M.UseLane{M.Any{}}, 52}
  , Sign{"I-7j", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Pilihan Memasuki Salah Satu Jalur atau Lajur yang Ditunjuk", M.UseLane{M.Any{}}, 53}
  , Sign{"I-7k", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Kecepatan Minimum yang Diperintahkan, Contoh: 40 km/jam", M.MinSpeed{40}, 54}
  , Sign{"I-7l", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Rantai Khusus Ban", M.UseChains{}, 55}
  , Sign{"I-7m", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Sepeda Motor", M.UseLane{M.Motorcycle{}}, 56}
  , Sign{"I-7n", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Bermotor Umum", M.UseLane{M.Public{}}, 57}
  , Sign{"I-7o", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Mobil Barang", M.UseLane{M.Truck{}}, 58}
  , Sign{"I-7p", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Pejalan Kaki", M.UseLane{M.Pedestrian{}}, 59}
  , Sign{"I-7q", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Sepeda", M.UseLane{M.Bicycle{}}, 60}
  , Sign{"I-7r", Elektronik{}, "Piktogram Rambu Perintah", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Delman", M.UseLane{M.Delman{}}, 61}
  , Sign{"I-10a", Elektronik{}, "Piktogram Rambu Petunjuk", M.Guidance{}, "Pendahulu Petunjuk Jurusan pada Persimpangan di Depan", M.NoDuty{}, 62}
  , Sign{"I-10b", Elektronik{}, "Piktogram Rambu Petunjuk", M.Guidance{}, "Rute Perjalanan", M.NoDuty{}, 63}
  , Sign{"I-10c", Elektronik{}, "Piktogram Rambu Petunjuk", M.Guidance{}, "Pendahulu Petunjuk Jurusan yang Menunjukkan Jurusan yang Dituju", M.NoDuty{}, 64}
  , Sign{"II-1a", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan ke Kiri", M.NoDuty{}, 65}
  , Sign{"II-1b", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan ke Kanan", M.NoDuty{}, 66}
  , Sign{"II-1c", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Ganda dengan Tikungan Pertama ke Kiri", M.NoDuty{}, 67}
  , Sign{"II-1d", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Ganda dengan Tikungan Pertama ke Kanan", M.NoDuty{}, 68}
  , Sign{"II-1e", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Tajam ke Kiri", M.NoDuty{}, 69}
  , Sign{"II-1f", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Tajam ke Kanan", M.NoDuty{}, 70}
  , Sign{"II-1g", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Tajam Ganda dengan Tikungan Pertama ke Kiri", M.NoDuty{}, 71}
  , Sign{"II-1h", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Tajam Ganda dengan Tikungan Pertama ke Kanan", M.NoDuty{}, 72}
  , Sign{"II-1i", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Banyak Tikungan dengan Tikungan Pertama ke Kiri", M.NoDuty{}, 73}
  , Sign{"II-1j", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Banyak Tikungan dengan Tikungan Pertama ke Kanan", M.NoDuty{}, 74}
  , Sign{"II-1k", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Memutar ke Kiri", M.NoDuty{}, 75}
  , Sign{"II-1l", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Tikungan Memutar ke Kanan", M.NoDuty{}, 76}
  , Sign{"II-1m", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kiri dan Kanan", M.NoDuty{}, 77}
  , Sign{"II-1n", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kiri dan Kanan", M.NoDuty{}, 78}
  , Sign{"II-1o", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kiri", M.NoDuty{}, 79}
  , Sign{"II-1p", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kanan", M.NoDuty{}, 80}
  , Sign{"II-1q", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kiri", M.NoDuty{}, 81}
  , Sign{"II-1r", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kanan", M.NoDuty{}, 82}
  , Sign{"II-1s", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pengurangan Lajur Kiri", M.NoDuty{}, 83}
  , Sign{"II-1t", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pengurangan Lajur Kanan", M.NoDuty{}, 84}
  , Sign{"II-1u", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penambahan Lajur Kiri", M.NoDuty{}, 85}
  , Sign{"II-1v", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penambahan Lajur Kanan", M.NoDuty{}, 86}
  , Sign{"II-1w", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Jembatan; Peringatan Penyempitan Bagan Jalinan Jalan Tertentu", M.NoDuty{}, 87}
  , Sign{"II-2a", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Vertikal", M.Warning{}, "Peringatan Turunan Landai", M.NoDuty{}, 88}
  , Sign{"II-2b", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Vertikal", M.Warning{}, "Peringatan Turunan Curam", M.NoDuty{}, 89}
  , Sign{"II-2c", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Vertikal", M.Warning{}, "Peringatan Tanjakan Landai", M.NoDuty{}, 90}
  , Sign{"II-2d", Peringatan{}, "Rambu Peringatan Perubahan Kondisi Alinyemen Vertikal", M.Warning{}, "Peringatan Tanjakan Curam", M.NoDuty{}, 91}
  , Sign{"II-3a", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Permukaan Jalan yang Licin", M.NoDuty{}, 92}
  , Sign{"II-3b", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Bagian Tepi Jalan yang Tidak Sama Tinggi dengan Badan Jalan", M.NoDuty{}, 93}
  , Sign{"II-3c", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Jurang", M.NoDuty{}, 94}
  , Sign{"II-3d", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Tepi Air", M.NoDuty{}, 95}
  , Sign{"II-3e", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Permukaan Jalan yang Cekung atau Berlubang", M.NoDuty{}, 96}
  , Sign{"II-3f", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Permukaan Jalan yang Cembung; Peringatan Alat Pembatas Kecepatan", M.NoDuty{}, 97}
  , Sign{"II-3g", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Jalan Bergelombang", M.NoDuty{}, 98}
  , Sign{"II-3h", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Lontaran Kerikil", M.NoDuty{}, 99}
  , Sign{"II-3i", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Bagian Tepi Jalan Sebelah Kiri yang Rawan Runtuh", M.NoDuty{}, 100}
  , Sign{"II-3j", Peringatan{}, "Rambu Peringatan Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Bagian Tepi Jalan Sebelah Kanan yang Rawan Runtuh", M.NoDuty{}, 101}
  , Sign{"II-4a1", Peringatan{}, "Rambu Peringatan Pengaturan Persinyalan", M.Warning{}, "Peringatan Alat Pemberi Isyarat Lalu Lintas", M.NoDuty{}, 102}
  , Sign{"II-4a2", Peringatan{}, "Rambu Peringatan Pengaturan Persinyalan", M.Warning{}, "Peringatan Lampu Isyarat Penyeberang Jalan", M.NoDuty{}, 103}
  , Sign{"II-4b1", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Simpang Empat Prioritas (Ditempatkan pada Lengan Minor)", M.NoDuty{}, 104}
  , Sign{"II-4b2", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Simpang Empat Prioritas (Ditempatkan pada Lengan Mayor)", M.NoDuty{}, 105}
  , Sign{"II-4b3", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Bundaran dengan Prioritas", M.NoDuty{}, 106}
  , Sign{"II-4b4", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Serong Kiri (Ditempatkan pada Lengan Minor)", M.NoDuty{}, 107}
  , Sign{"II-4b5", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Serong Kanan (Ditempatkan pada Lengan Minor)", M.NoDuty{}, 108}
  , Sign{"II-4b6", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Serong Kiri (Ditempatkan pada Lengan Mayor)", M.NoDuty{}, 109}
  , Sign{"II-4b7", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Serong Kanan (Ditempatkan pada Lengan Mayor)", M.NoDuty{}, 110}
  , Sign{"II-4b8", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Sisi Kiri (Ditempatkan pada Lengan Minor)", M.NoDuty{}, 111}
  , Sign{"II-4b9", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Sisi Kanan (Ditempatkan pada Lengan Minor)", M.NoDuty{}, 112}
  , Sign{"II-4b10", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Berganda Sisi Kiri dan Kanan (Ditempatkan pada Lengan Mayor)", M.NoDuty{}, 113}
  , Sign{"II-4b11", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Berganda Sisi Kanan dan Kiri (Ditempatkan pada Lengan Mayor)", M.NoDuty{}, 114}
  , Sign{"II-4b12", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Serong Kiri", M.NoDuty{}, 115}
  , Sign{"II-4b13", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Serong Kanan", M.NoDuty{}, 116}
  , Sign{"II-4b14", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Berganda Sisi Kiri (Ditempatkan pada Lengan Mayor)", M.NoDuty{}, 117}
  , Sign{"II-4b15", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Berganda Sisi Kanan (Ditempatkan pada Lengan Mayor)", M.NoDuty{}, 118}
  , Sign{"II-4b16", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Sisi Kiri (Ditempatkan pada Lengan Mayor)", M.NoDuty{}, 119}
  , Sign{"II-4b17", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Sisi Kanan (Ditempatkan pada Lengan Mayor)", M.NoDuty{}, 120}
  , Sign{"II-4b18", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Tipe T (Ditempatkan pada Lengan Minor)", M.NoDuty{}, 121}
  , Sign{"II-4b19", Peringatan{}, "Rambu Peringatan Persimpangan Prioritas", M.Warning{}, "Peringatan Persimpangan Tiga Tipe Y", M.NoDuty{}, 122}
  , Sign{"II-4c1", Peringatan{}, "Rambu Peringatan Konstruksi Pemisah Jalur Lalu Lintas", M.Warning{}, "Peringatan Awal Pembatas Konstruksi Fisik Pemisah Jalur Lalu Lintas Dua Arah", M.NoDuty{}, 123}
  , Sign{"II-4c2", Peringatan{}, "Rambu Peringatan Konstruksi Pemisah Jalur Lalu Lintas", M.Warning{}, "Peringatan Akhir Pembatas Konstruksi Fisik Pemisah Jalur Lalu Lintas Dua Arah", M.NoDuty{}, 124}
  , Sign{"II-4c3", Peringatan{}, "Rambu Peringatan Konstruksi Pemisah Jalur Lalu Lintas", M.Warning{}, "Peringatan Awal Pembatas Konstruksi Fisik Pemisah Jalur Lalu Lintas Satu Arah; Peringatan Awal Pembatas Konstruksi Fisik Pemisah Lajur Lalu Lintas", M.NoDuty{}, 125}
  , Sign{"II-4c4", Peringatan{}, "Rambu Peringatan Konstruksi Pemisah Jalur Lalu Lintas", M.Warning{}, "Peringatan Akhir Pembatas Konstruksi Fisik Pemisah Jalur Lalu Lintas Satu Arah; Peringatan Akhir Pembatas Konstruksi Fisik Pemisah Lajur Lalu Lintas", M.NoDuty{}, 126}
  , Sign{"II-5a", Peringatan{}, "Rambu Peringatan Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Angkutan Barang", M.NoDuty{}, 127}
  , Sign{"II-5b", Peringatan{}, "Rambu Peringatan Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Angkutan Barang Tipe Curah/Cair", M.NoDuty{}, 128}
  , Sign{"II-5c", Peringatan{}, "Rambu Peringatan Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Angkutan Barang Berbahaya dan Beracun", M.NoDuty{}, 129}
  , Sign{"II-5d", Peringatan{}, "Rambu Peringatan Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Angkutan Barang Mudah Terbakar", M.NoDuty{}, 130}
  , Sign{"II-5e", Peringatan{}, "Rambu Peringatan Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Angkutan Umum", M.NoDuty{}, 131}
  , Sign{"II-5f", Peringatan{}, "Rambu Peringatan Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Kendaraan Berat", M.NoDuty{}, 132}
  , Sign{"II-6a", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Pejalan Kaki Menggunakan Fasilitas Penyeberangan", M.NoDuty{}, 133}
  , Sign{"II-6b", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Pejalan Kaki", M.NoDuty{}, 134}
  , Sign{"II-6c", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Pejalan Kaki Anak-anak", M.NoDuty{}, 135}
  , Sign{"II-6d", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Penyandang Cacat", M.NoDuty{}, 136}
  , Sign{"II-6e", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Lalu Lintas Sepeda", M.NoDuty{}, 137}
  , Sign{"II-6f", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Hewan Ternak Melintas", M.NoDuty{}, 138}
  , Sign{"II-6g", Peringatan{}, "Rambu Peringatan Selain Lalu Lintas Kendaraan Bermotor", M.Warning{}, "Peringatan Banyak Hewan Liar Melintas", M.NoDuty{}, 139}
  , Sign{"II-7a", Peringatan{}, "Rambu Peringatan Kawasan Rawan Bencana", M.Warning{}, "Peringatan Kawasan Rawan Bencana Tsunami", M.NoDuty{}, 140}
  , Sign{"II-7b", Peringatan{}, "Rambu Peringatan Kawasan Rawan Bencana", M.Warning{}, "Peringatan Kawasan Rawan Bencana Gempa Bumi", M.NoDuty{}, 141}
  , Sign{"II-7c", Peringatan{}, "Rambu Peringatan Kawasan Rawan Bencana", M.Warning{}, "Peringatan Kawasan Rawan Bencana Gunung Api", M.NoDuty{}, 142}
  , Sign{"II-8a", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan yang Ditegaskan Penjelasan Jenis Peringatan dengan Menggunakan Papan Tambahan", M.NoDuty{}, 143}
  , Sign{"II-8b", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Pekerjaan di Jalan", M.NoDuty{}, 144}
  , Sign{"II-8c", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Tinggi Ruang Bebas (... m)", M.NoDuty{}, 145}
  , Sign{"II-8d", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Lebar Ruang Bebas (... m)", M.NoDuty{}, 146}
  , Sign{"II-8e", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Pintu Perlintasan Sebidang Kereta Api", M.NoDuty{}, 147}
  , Sign{"II-8f", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Perlintasan Sebidang Kereta Api tanpa Pintu", M.NoDuty{}, 148}
  , Sign{"II-8g", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Lalu Lintas Pesawat Terbang yang Terbang Rendah", M.NoDuty{}, 149}
  , Sign{"II-8h", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Hembusan Angin Kencang", M.NoDuty{}, 150}
  , Sign{"II-8i", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Lalu Lintas Dua Arah", M.NoDuty{}, 151}
  , Sign{"II-8j", Peringatan{}, "Rambu Peringatan Lainnya", M.Warning{}, "Peringatan Jembatan Angkat", M.NoDuty{}, 152}
  , Sign{"II-10a", Peringatan{}, "Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis", M.Warning{}, "Peringatan yang Menerangkan bahwa Lokasi Kritis Berjarak 450 m dari Lokasi Rambu", M.NoDuty{}, 153}
  , Sign{"II-10b", Peringatan{}, "Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis", M.Warning{}, "Peringatan yang Menerangkan bahwa Lokasi Kritis Berjarak 300 m dari Lokasi Rambu", M.NoDuty{}, 154}
  , Sign{"II-10c", Peringatan{}, "Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis", M.Warning{}, "Peringatan yang Menerangkan bahwa Lokasi Kritis Berjarak 150 m dari Lokasi Rambu", M.NoDuty{}, 155}
  , Sign{"II-11a", Peringatan{}, "Rambu Peringatan Pengarah Gerakan Lalu Lintas", M.Warning{}, "Peringatan Rintangan atau Objek Berbahaya pada Sisi Jalan Sebelah Kiri (Hanya Dapat Melakukan Gerakan Lalu Lintas pada Sisi Sebelah Kanan)", M.NoDuty{}, 156}
  , Sign{"II-11b", Peringatan{}, "Rambu Peringatan Pengarah Gerakan Lalu Lintas", M.Warning{}, "Peringatan Rintangan atau Objek Berbahaya pada Sisi Jalan Sebelah Kanan (Hanya Dapat Melakukan Gerakan Lalu Lintas pada Sisi Sebelah Kiri)", M.NoDuty{}, 157}
  , Sign{"II-11c", Peringatan{}, "Rambu Peringatan Pengarah Gerakan Lalu Lintas", M.Warning{}, "Peringatan Rintangan atau Objek Berbahaya pada Pemisah Lajur atau Jalur (Dapat Melakukan Gerakan Lalu Lintas pada Kedua Sisi)", M.NoDuty{}, 158}
  , Sign{"II-11d", Peringatan{}, "Rambu Peringatan Pengarah Gerakan Lalu Lintas", M.Warning{}, "Pengarah Tikungan ke Kiri", M.NoDuty{}, 159}
  , Sign{"II-11e", Peringatan{}, "Rambu Peringatan Pengarah Gerakan Lalu Lintas", M.Warning{}, "Pengarah Tikungan ke Kanan", M.NoDuty{}, 160}
  , Sign{"III-1a", Larangan{}, "Rambu Larangan Berjalan Terus", M.Prohibition{}, "Larangan Berjalan Terus karena Wajib Berhenti Sesaat dan/atau Melanjutkan Perjalanan Setelah Dipastikan Selamat dari Konflik Lalu Lintas dari Arah Lainnya", M.Stop{}, 161}
  , Sign{"III-1b", Larangan{}, "Rambu Larangan Berjalan Terus", M.Prohibition{}, "Larangan Berjalan Terus karena Wajib Memberi Prioritas kepada Arus Lalu Lintas dari Arah yang Diberi Prioritas", M.GiveWay{}, 162}
  , Sign{"III-1c", Larangan{}, "Rambu Larangan Berjalan Terus", M.Prohibition{}, "Larangan Berjalan Terus Sebelum Melaksanakan Kegiatan Tertentu, Contoh: Larangan Melanjutkan Perjalanan Sebelum Membayar Tarif Tol", M.Stop{}, 163}
  , Sign{"III-1d", Larangan{}, "Rambu Larangan Berjalan Terus", M.Prohibition{}, "Larangan Berjalan Terus pada Bagian Jalan Tertentu Sebelum Mendahulukan Arus Lalu Lintas yang Datang dari Arah Berlawanan", M.GiveWay{}, 164}
  , Sign{"III-1e", Larangan{}, "Rambu Larangan Berjalan Terus", M.Prohibition{}, "Larangan Berjalan Terus pada Perlintasan Sebidang Lintasan Kereta Api Jalur Tunggal Sebelum Mendapatkan Kepastian Selamat dari Konflik", M.Stop{}, 165}
  , Sign{"III-1f", Larangan{}, "Rambu Larangan Berjalan Terus", M.Prohibition{}, "Larangan Berjalan Terus pada Perlintasan Sebidang Lintasan Kereta Api Jalur Ganda Sebelum Mendapatkan Kepastian Selamat dari Konflik", M.Stop{}, 166}
  , Sign{"III-2a1", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor dan Tidak Bermotor", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dan Tidak Bermotor dari Kedua Arah", M.NoEntry{[M.Any{}]}, 167}
  , Sign{"III-2a2", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor dan Tidak Bermotor", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dan Tidak Bermotor", M.NoEntry{[M.Any{}]}, 168}
  , Sign{"III-2b1", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Sepeda Motor", M.NoEntry{[M.Motorcycle{}]}, 169}
  , Sign{"III-2b2", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor Roda Tiga", M.NoEntry{[M.ThreeWheel{}]}, 170}
  , Sign{"III-2b3", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Mobil Penumpang", M.NoEntry{[M.Car{}]}, 171}
  , Sign{"III-2b4", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Mobil Barang", M.NoEntry{[M.Truck{}]}, 172}
  , Sign{"III-2b5", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Mobil Bus", M.NoEntry{[M.Bus{}]}, 173}
  , Sign{"III-2b6", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Khusus", M.NoEntry{[M.Special{}]}, 174}
  , Sign{"III-2b7", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Kereta Tempel", M.NoEntry{[M.Trailer{}]}, 175}
  , Sign{"III-2b8", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Kereta Gandeng", M.NoEntry{[M.Trailer{}]}, 176}
  , Sign{"III-2b9", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Sepeda Motor dan Mobil Penumpang", M.NoEntry{[M.Motorcycle{}, M.Car{}]}, 177}
  , Sign{"III-2b10", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Mobil Penumpang Perseorangan dan Mobil Barang", M.NoEntry{[M.Car{}, M.Truck{}]}, 178}
  , Sign{"III-2b11", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Mobil Barang dan Kendaraan Bermotor Umum", M.NoEntry{[M.Truck{}, M.Public{}]}, 179}
  , Sign{"III-2b12", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Sepeda Motor, Mobil Penumpang Perseorangan dan Mobil Barang", M.NoEntry{[M.Motorcycle{}, M.Car{}, M.Truck{}]}, 180}
  , Sign{"III-2b13", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Mobil Penumpang Perseorangan, Mobil Barang dan Kendaraan Bermotor Umum", M.NoEntry{[M.Car{}, M.Truck{}, M.Public{}]}, 181}
  , Sign{"III-2c1", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Pejalan Kaki", M.NoEntry{[M.Pedestrian{}]}, 182}
  , Sign{"III-2c2", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Gerobak Dorong dan Sejenisnya", M.NoEntry{[M.Cart{}]}, 183}
  , Sign{"III-2c3", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Sepeda", M.NoEntry{[M.Bicycle{}]}, 184}
  , Sign{"III-2c4", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Becak", M.NoEntry{[M.Becak{}]}, 185}
  , Sign{"III-2c5", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Pedati", M.NoEntry{[M.Pedati{}]}, 186}
  , Sign{"III-2c6", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Delman/Dokar", M.NoEntry{[M.Delman{}]}, 187}
  , Sign{"III-2c7", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Sepeda dan Becak", M.NoEntry{[M.Bicycle{}, M.Becak{}]}, 188}
  , Sign{"III-2c8", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Delman dan Pedati", M.NoEntry{[M.Delman{}, M.Pedati{}]}, 189}
  , Sign{"III-2c9", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan Tidak Bermotor Jenis Tertentu", M.Prohibition{}, "Larangan Masuk bagi Semua Jenis Kendaraan Tidak Bermotor", M.NoEntry{[M.NonMotorized{}]}, 190}
  , Sign{"III-2d1", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Panjang Lebih dari ... m", M.LengthLimit{0}, 191}
  , Sign{"III-2d2", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Tinggi Lebih dari ... m", M.HeightLimit{0}, 192}
  , Sign{"III-2d3", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Lebar Lebih dari ... m", M.WidthLimit{0}, 193}
  , Sign{"III-2d4", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Tidak Bermotor dengan Panjang Lebih dari ... m", M.LengthLimit{0}, 194}
  , Sign{"III-2d5", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Jumlah Berat yang Diizinkan (JBI) Sama atau Lebih dari 5 ton", M.WeightLimit{5}, 195}
  , Sign{"III-2d6", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor Roda Tunggal dengan Muatan Sumbu Terberat (MST) Sama atau Lebih dari 8 ton", M.AxleLimit{8}, 196}
  , Sign{"III-2d7", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor Roda Ganda atau Lebih dengan Muatan Sumbu Terberat (MST) Sama atau Lebih dari 8 ton", M.AxleLimit{8}, 197}
  , Sign{"III-2d8", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Roda Tunggal pada Ujung Sumbu dengan Berat Muatan Sama atau Lebih dari 8 ton", M.AxleLimit{8}, 198}
  , Sign{"III-2d9", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan Bermotor dengan Roda Ganda atau Lebih pada Ujung Sumbu dengan Berat Muatan Sama atau Lebih dari 8 ton", M.AxleLimit{8}, 199}
  , Sign{"III-2d10", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan dengan Ukuran Lebar Melebihi 2.500 Milimeter, Ukuran Panjang Melebihi 18.000 Milimeter, Ukuran Paling Tinggi 4.200 Milimeter, dan Muatan Sumbu Terberat 10 ton", M.DimensionLimit{2500, 18000, 4200, 10}, 200}
  , Sign{"III-2d11", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan dengan Ukuran Lebar Melebihi 2.500 Milimeter, Ukuran Panjang Melebihi 12.000 Milimeter, Ukuran Paling Tinggi 4.200 Milimeter, dan Muatan Sumbu Terberat 8 ton", M.DimensionLimit{2500, 12000, 4200, 8}, 201}
  , Sign{"III-2d12", Larangan{}, "Rambu Larangan Masuk bagi Kendaraan dengan Berat dan Dimensi Tertentu", M.Prohibition{}, "Larangan Masuk bagi Kendaraan dengan Ukuran Lebar Melebihi 2.100 Milimeter, Ukuran Panjang Melebihi 9.000 Milimeter, Ukuran Paling Tinggi 3.500 Milimeter, dan Muatan Sumbu Terberat 8 ton", M.DimensionLimit{2100, 9000, 3500, 8}, 202}
  , Sign{"III-3a", Larangan{}, "Rambu Larangan Parkir dan Berhenti", M.Prohibition{}, "Larangan Berhenti", M.NoStopping{}, 203}
  , Sign{"III-3b", Larangan{}, "Rambu Larangan Parkir dan Berhenti", M.Prohibition{}, "Larangan Parkir", M.NoParking{}, 204}
  , Sign{"III-4a", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Berjalan Terus", M.Stop{}, 205}
  , Sign{"III-4b", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Belok Kiri", M.NoLeftTurn{}, 206}
  , Sign{"III-4c", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Belok Kanan", M.NoRightTurn{}, 207}
  , Sign{"III-4d", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Menyalip Kendaraan Lain", M.NoOvertaking{}, 208}
  , Sign{"III-4e", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Memutar Balik", M.NoUTurn{}, 209}
  , Sign{"III-4f", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Memutar Balik dan Belok Kanan", M.NoUTurnOrRight{}, 210}
  , Sign{"III-4g", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Mendekati Kendaraan di Depan dengan Jarak Sama atau Kurang dari ... m", M.NoCloseFollowing{0}, 211}
  , Sign{"III-4h", Larangan{}, "Rambu Larangan Pergerakan Lalu Lintas Tertentu", M.Prohibition{}, "Larangan Menjalankan Kendaraan dengan Kecepatan Lebih dari yang Tertulis, Contoh: Kecepatan Maksimum Kendaraan yang Dilarang adalah 50 km/jam", M.MaxSpeed{50}, 212}
  , Sign{"IV-1a", Perintah{}, "Rambu Perintah Mematuhi Arah yang Ditunjuk", M.Command{}, "Perintah Mengikuti ke Arah Kiri", M.KeepLeft{}, 213}
  , Sign{"IV-1b", Perintah{}, "Rambu Perintah Mematuhi Arah yang Ditunjuk", M.Command{}, "Perintah Mengikuti ke Arah Kanan", M.KeepRight{}, 214}
  , Sign{"IV-1c", Perintah{}, "Rambu Perintah Mematuhi Arah yang Ditunjuk", M.Command{}, "Perintah Belok ke Arah Kiri", M.TurnLeft{}, 215}
  , Sign{"IV-1d", Perintah{}, "Rambu Perintah Mematuhi Arah yang Ditunjuk", M.Command{}, "Perintah Belok ke Arah Kanan", M.TurnRight{}, 216}
  , Sign{"IV-1e", Perintah{}, "Rambu Perintah Mematuhi Arah yang Ditunjuk", M.Command{}, "Perintah Berjalan Lurus", M.GoStraight{}, 217}
  , Sign{"IV-1f", Perintah{}, "Rambu Perintah Mematuhi Arah yang Ditunjuk", M.Command{}, "Perintah Mengikuti Arah yang Ditunjukkan saat Memasuki Bundaran", M.Roundabout{}, 218}
  , Sign{"IV-2a", Perintah{}, "Rambu Perintah Memilih Salah Satu Arah yang Ditunjuk", M.Command{}, "Perintah Memilih Lurus atau Belok Kiri", M.ChoosePath{}, 219}
  , Sign{"IV-2b", Perintah{}, "Rambu Perintah Memilih Salah Satu Arah yang Ditunjuk", M.Command{}, "Perintah Memilih Lurus atau Belok Kanan", M.ChoosePath{}, 220}
  , Sign{"IV-3a", Perintah{}, "Rambu Perintah Memasuki Bagian Jalan Tertentu", M.Command{}, "Perintah Memasuki Jalur atau Lajur yang Ditunjuk", M.UseLane{M.Any{}}, 221}
  , Sign{"IV-3b", Perintah{}, "Rambu Perintah Memasuki Bagian Jalan Tertentu", M.Command{}, "Perintah Memasuki Jalur atau Lajur yang Ditunjuk", M.UseLane{M.Any{}}, 222}
  , Sign{"IV-3c", Perintah{}, "Rambu Perintah Memasuki Bagian Jalan Tertentu", M.Command{}, "Perintah Pilihan Memasuki Salah Satu Jalur atau Lajur yang Ditunjuk", M.UseLane{M.Any{}}, 223}
  , Sign{"IV-4", Perintah{}, "Rambu Perintah Batas Minimum Kecepatan", M.Command{}, "Kecepatan Minimum yang Diperintahkan, Contoh: 50 km/jam", M.MinSpeed{50}, 224}
  , Sign{"IV-5", Perintah{}, "Rambu Perintah Penggunaan Rantai Ban", M.Command{}, "Perintah Menggunakan Rantai Khusus Ban", M.UseChains{}, 225}
  , Sign{"IV-6a1", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Sepeda Motor", M.UseLane{M.Motorcycle{}}, 226}
  , Sign{"IV-6a2", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Mobil Bus", M.UseLane{M.Bus{}}, 227}
  , Sign{"IV-6a3", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Mobil Barang", M.UseLane{M.Truck{}}, 228}
  , Sign{"IV-6b1", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Pejalan Kaki", M.UseLane{M.Pedestrian{}}, 229}
  , Sign{"IV-6b2", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Penunggang Kuda", M.UseLane{M.HorseRider{}}, 230}
  , Sign{"IV-6b3", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Sepeda", M.UseLane{M.Bicycle{}}, 231}
  , Sign{"IV-6b4", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Becak", M.UseLane{M.Becak{}}, 232}
  , Sign{"IV-6b5", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Pedati", M.UseLane{M.Pedati{}}, 233}
  , Sign{"IV-6b6", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Delman", M.UseLane{M.Delman{}}, 234}
  , Sign{"IV-6b7", Perintah{}, "Rambu Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.Command{}, "Perintah Menggunakan Jalur atau Lajur Lalu Lintas Khusus Kendaraan Tidak Bermotor", M.UseLane{M.NonMotorized{}}, 235}
  , Sign{"IV-7a", Perintah{}, "Rambu Batas Akhir Perintah Tertentu", M.Command{}, "Batas Akhir Kecepatan Minimum yang Diperintahkan", M.EndOfRestriction{}, 236}
  , Sign{"IV-7b", Perintah{}, "Rambu Batas Akhir Perintah Tertentu", M.Command{}, "Batas Akhir Perintah Menggunakan Rantai Khusus Ban", M.EndOfRestriction{}, 237}
  , Sign{"V-1a", Petunjuk{}, "Rambu Petunjuk Pendahulu Jurusan", M.Guidance{}, "Pendahulu Petunjuk Jurusan pada Persimpangan di Depan", M.NoDuty{}, 238}
  , Sign{"V-1b", Petunjuk{}, "Rambu Petunjuk Pendahulu Jurusan", M.Guidance{}, "Pendahulu Petunjuk Jurusan yang Menunjukkan Jurusan yang Dituju", M.NoDuty{}, 239}
  , Sign{"V-1c", Petunjuk{}, "Rambu Petunjuk Pendahulu Jurusan", M.Guidance{}, "Pendahulu Petunjuk Jurusan yang Menunjukkan Jalur atau Lajur untuk Mencapai Jurusan yang Dituju pada Pintu Keluar Jalan Tol", M.NoDuty{}, 240}
  , Sign{"V-1d", Petunjuk{}, "Rambu Petunjuk Pendahulu Jurusan", M.Guidance{}, "Pendahulu Petunjuk Jurusan yang Menunjukkan Jalur atau Lajur Sebelah Kiri untuk Mencapai Jurusan yang Dituju", M.NoDuty{}, 241}
  , Sign{"V-1e", Petunjuk{}, "Rambu Petunjuk Pendahulu Jurusan", M.Guidance{}, "Pendahulu Petunjuk Jurusan yang Menunjukkan Jalur atau Lajur Sebelah Kanan untuk Mencapai Jurusan yang Dituju", M.NoDuty{}, 242}
  , Sign{"V-1f", Petunjuk{}, "Rambu Petunjuk Pendahulu Jurusan", M.Guidance{}, "Pendahulu Petunjuk Jurusan yang Menunjukkan Jarak Jurusan yang Dituju", M.NoDuty{}, 243}
  , Sign{"V-3a", Petunjuk{}, "Rambu Petunjuk Batas Wilayah", M.Guidance{}, "Rambu Petunjuk Batas Awal Wilayah (Contoh: Kabupaten Toli-Toli)", M.NoDuty{}, 244}
  , Sign{"V-3b", Petunjuk{}, "Rambu Petunjuk Batas Wilayah", M.Guidance{}, "Rambu Petunjuk Batas Akhir Wilayah (Contoh: Kabupaten Toli-Toli)", M.NoDuty{}, 245}
  , Sign{"V-4a", Petunjuk{}, "Rambu Petunjuk Batas Jalan Tol", M.Guidance{}, "Rambu Petunjuk Batas Awal Jalan Tol", M.NoDuty{}, 246}
  , Sign{"V-4b", Petunjuk{}, "Rambu Petunjuk Batas Jalan Tol", M.Guidance{}, "Rambu Petunjuk Batas Akhir Jalan Tol", M.NoDuty{}, 247}
  , Sign{"V-4c", Petunjuk{}, "Rambu Petunjuk Batas Jalan Tol", M.Guidance{}, "Rambu Petunjuk Batas Awal Jalan Tol Lingkar Dalam", M.NoDuty{}, 248}
  , Sign{"V-4d", Petunjuk{}, "Rambu Petunjuk Batas Jalan Tol", M.Guidance{}, "Rambu Petunjuk Batas Akhir Jalan Tol Lingkar Dalam", M.NoDuty{}, 249}
  , Sign{"V-5a1", Petunjuk{}, "Rambu Petunjuk Lokasi Simpul Transportasi", M.Guidance{}, "Petunjuk Lokasi Terminal Kendaraan Bermotor Umum", M.NoDuty{}, 250}
  , Sign{"V-5a2", Petunjuk{}, "Rambu Petunjuk Lokasi Simpul Transportasi", M.Guidance{}, "Petunjuk Lokasi Stasiun Kereta Api", M.NoDuty{}, 251}
  , Sign{"V-5a3", Petunjuk{}, "Rambu Petunjuk Lokasi Simpul Transportasi", M.Guidance{}, "Petunjuk Lokasi Pelabuhan", M.NoDuty{}, 252}
  , Sign{"V-5a4", Petunjuk{}, "Rambu Petunjuk Lokasi Simpul Transportasi", M.Guidance{}, "Petunjuk Lokasi Bandar Udara", M.NoDuty{}, 253}
  , Sign{"V-5b1", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Kebersihan", M.Guidance{}, "Petunjuk Lokasi Tempat Penampungan Sampah", M.NoDuty{}, 254}
  , Sign{"V-5b2", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Kebersihan", M.Guidance{}, "Petunjuk Lokasi Tempat Pembuangan Sampah", M.NoDuty{}, 255}
  , Sign{"V-5c1", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Komunikasi", M.Guidance{}, "Petunjuk Lokasi Kantor Pos", M.NoDuty{}, 256}
  , Sign{"V-5c2", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Komunikasi", M.Guidance{}, "Petunjuk Lokasi Telepon Umum", M.NoDuty{}, 257}
  , Sign{"V-5d1", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Pemberhentian Angkutan Umum", M.Guidance{}, "Petunjuk Lokasi Fasilitas Pemberhentian Mobil Bus Umum", M.NoDuty{}, 258}
  , Sign{"V-5d2", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Pemberhentian Angkutan Umum", M.Guidance{}, "Petunjuk Lokasi Fasilitas Pangkalan Taksi", M.NoDuty{}, 259}
  , Sign{"V-5d3", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Pemberhentian Angkutan Umum", M.Guidance{}, "Petunjuk Lokasi Fasilitas Pemberhentian dan/atau Pangkalan Angkutan Umum Selain Mobil Bus Umum dan Taksi", M.NoDuty{}, 260}
  , Sign{"V-5f1", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Parkir", M.Guidance{}, "Petunjuk Lokasi Fasilitas Parkir", M.NoDuty{}, 261}
  , Sign{"V-5f2", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Parkir", M.Guidance{}, "Petunjuk Lokasi Fasilitas Parkir Tertentu, Contoh: Petunjuk Lokasi Fasilitas Parkir Penyandang Cacat", M.NoDuty{}, 262}
  , Sign{"V-5g1", Petunjuk{}, "Rambu Petunjuk Terowongan", M.Guidance{}, "Petunjuk Awal Terowongan", M.NoDuty{}, 263}
  , Sign{"V-5g2", Petunjuk{}, "Rambu Petunjuk Terowongan", M.Guidance{}, "Petunjuk Akhir Terowongan", M.NoDuty{}, 264}
  , Sign{"V-5h1", Petunjuk{}, "Rambu Petunjuk Fasilitas Tanggap Bencana", M.Guidance{}, "Petunjuk Jalur Evakuasi Tsunami", M.NoDuty{}, 265}
  , Sign{"V-5h2", Petunjuk{}, "Rambu Petunjuk Fasilitas Tanggap Bencana", M.Guidance{}, "Petunjuk Jalur Evakuasi Gempa Bumi", M.NoDuty{}, 266}
  , Sign{"V-5h3", Petunjuk{}, "Rambu Petunjuk Fasilitas Tanggap Bencana", M.Guidance{}, "Petunjuk Jalur Evakuasi Gunung Meletus", M.NoDuty{}, 267}
  , Sign{"V-5h4", Petunjuk{}, "Rambu Petunjuk Fasilitas Tanggap Bencana", M.Guidance{}, "Petunjuk Lokasi Tempat Berkumpul Darurat", M.NoDuty{}, 268}
  , Sign{"V-5h5", Petunjuk{}, "Rambu Petunjuk Fasilitas Tanggap Bencana", M.Guidance{}, "Petunjuk Lokasi Tempat Kemah Pengungsian", M.NoDuty{}, 269}
  , Sign{"V-5h6", Petunjuk{}, "Rambu Petunjuk Fasilitas Tanggap Bencana", M.Guidance{}, "Petunjuk Lokasi Bangunan Pengungsian", M.NoDuty{}, 270}
  , Sign{"V-6a1", Petunjuk{}, "Rambu Petunjuk Lokasi Peribadatan", M.Guidance{}, "Petunjuk Lokasi Masjid", M.NoDuty{}, 271}
  , Sign{"V-6a2", Petunjuk{}, "Rambu Petunjuk Lokasi Peribadatan", M.Guidance{}, "Petunjuk Lokasi Gereja", M.NoDuty{}, 272}
  , Sign{"V-6a3", Petunjuk{}, "Rambu Petunjuk Lokasi Peribadatan", M.Guidance{}, "Petunjuk Lokasi Wihara", M.NoDuty{}, 273}
  , Sign{"V-6a4", Petunjuk{}, "Rambu Petunjuk Lokasi Peribadatan", M.Guidance{}, "Petunjuk Lokasi Pura", M.NoDuty{}, 274}
  , Sign{"V-6b1", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Rumah Sakit", M.NoDuty{}, 275}
  , Sign{"V-6b2", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Balai Kesehatan, Puskesmas, Balai Pertolongan Pertama dan yang Sejenis", M.NoDuty{}, 276}
  , Sign{"V-6b3", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Apotek", M.NoDuty{}, 277}
  , Sign{"V-6b4", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi SPBU", M.NoDuty{}, 278}
  , Sign{"V-6b5", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Unit Pelaksana Pengujian Berkala Kendaraan Bermotor", M.NoDuty{}, 279}
  , Sign{"V-6b6", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Unit Pelaksana Pengujian dan/atau Pemeriksaan Salah Satu Unsur Laik Jalan Kendaraan Bermotor, Contoh: Pemeriksaan Emisi Kendaraan Bermotor", M.NoDuty{}, 280}
  , Sign{"V-6b7", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Unit Pelaksana Penimbangan Kendaraan Bermotor", M.NoDuty{}, 281}
  , Sign{"V-6b8", Petunjuk{}, "Rambu Petunjuk Lokasi Pemerintahan dan Pelayanan Umum", M.Guidance{}, "Petunjuk Lokasi Museum", M.NoDuty{}, 282}
  , Sign{"V-6c1", Petunjuk{}, "Rambu Petunjuk Lokasi Perbelanjaan dan Niaga", M.Guidance{}, "Petunjuk Lokasi Pusat Perbelanjaan dan Pasar", M.NoDuty{}, 283}
  , Sign{"V-6c2", Petunjuk{}, "Rambu Petunjuk Lokasi Perbelanjaan dan Niaga", M.Guidance{}, "Petunjuk Lokasi Rumah Makan", M.NoDuty{}, 284}
  , Sign{"V-6c3", Petunjuk{}, "Rambu Petunjuk Lokasi Perbelanjaan dan Niaga", M.Guidance{}, "Petunjuk Lokasi Tempat Penjualan Minuman", M.NoDuty{}, 285}
  , Sign{"V-6c4", Petunjuk{}, "Rambu Petunjuk Lokasi Perbelanjaan dan Niaga", M.Guidance{}, "Petunjuk Lokasi Penginapan", M.NoDuty{}, 286}
  , Sign{"V-6c5", Petunjuk{}, "Rambu Petunjuk Lokasi Perbelanjaan dan Niaga", M.Guidance{}, "Petunjuk Lokasi Bengkel Kendaraan Bermotor", M.NoDuty{}, 287}
  , Sign{"V-6d1", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Taman", M.NoDuty{}, 288}
  , Sign{"V-6d2", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Rute Lintas Alam", M.NoDuty{}, 289}
  , Sign{"V-6d3", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Perkemahan", M.NoDuty{}, 290}
  , Sign{"V-6d4", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Perkemahan Menggunakan Kereta Kemah", M.NoDuty{}, 291}
  , Sign{"V-6d5", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Perkemahan dan Perkemahan Menggunakan Kereta Kemah", M.NoDuty{}, 292}
  , Sign{"V-6d6", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Vila", M.NoDuty{}, 293}
  , Sign{"V-6d7", Petunjuk{}, "Rambu Petunjuk Lokasi Rekreasi dan Kebudayaan", M.Guidance{}, "Petunjuk Lokasi Pantai", M.NoDuty{}, 294}
  , Sign{"V-6e1", Petunjuk{}, "Rambu Petunjuk Lokasi Sarana Olahraga dan Lapangan Terbuka", M.Guidance{}, "Petunjuk Lokasi Lapangan Terbuka", M.NoDuty{}, 295}
  , Sign{"V-6e2", Petunjuk{}, "Rambu Petunjuk Lokasi Sarana Olahraga dan Lapangan Terbuka", M.Guidance{}, "Petunjuk Lokasi Gedung Olah Raga", M.NoDuty{}, 296}
  , Sign{"V-6e3", Petunjuk{}, "Rambu Petunjuk Lokasi Sarana Olahraga dan Lapangan Terbuka", M.Guidance{}, "Petunjuk Lokasi Kolam Renang", M.NoDuty{}, 297}
  , Sign{"V-6e4", Petunjuk{}, "Rambu Petunjuk Lokasi Sarana Olahraga dan Lapangan Terbuka", M.Guidance{}, "Petunjuk Lokasi Stadium Olah Raga", M.NoDuty{}, 298}
  , Sign{"V-6f1", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Pendidikan", M.Guidance{}, "Petunjuk Lokasi Sekolah", M.NoDuty{}, 299}
  , Sign{"V-6f2", Petunjuk{}, "Rambu Petunjuk Lokasi Fasilitas Pendidikan", M.Guidance{}, "Petunjuk Lokasi Perpustakaan", M.NoDuty{}, 300}
  , Sign{"V-7a", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Sistem Satu Arah", M.NoDuty{}, 301}
  , Sign{"V-7b", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Sistem Satu Arah ke Kiri", M.NoDuty{}, 302}
  , Sign{"V-7c", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Sistem Satu Arah ke Kanan", M.NoDuty{}, 303}
  , Sign{"V-7d", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Jalan Buntu di Depan", M.NoDuty{}, 304}
  , Sign{"V-7e", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Jalan Buntu pada Belokan Sebelah Kanan", M.NoDuty{}, 305}
  , Sign{"V-7f", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Mendapatkan Prioritas Melanjutkan Perjalanan dari Arah Berlawanan", M.NoDuty{}, 306}
  , Sign{"V-7g", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Lokasi Putar Balik", M.NoDuty{}, 307}
  , Sign{"V-7h", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Awal Bagian Jalan untuk Kendaraan Bermotor", M.NoDuty{}, 308}
  , Sign{"V-7i", Petunjuk{}, "Rambu Petunjuk Pengaturan Lalu Lintas", M.Guidance{}, "Petunjuk Akhir Bagian Jalan untuk Kendaraan Bermotor", M.NoDuty{}, 309}
  , Sign{"V-10a", Petunjuk{}, "Bentuk Nomor Rute", M.Guidance{}, "Menyatakan Nomor Rute Asian Highway", M.NoDuty{}, 310}
  , Sign{"V-10b", Petunjuk{}, "Bentuk Nomor Rute", M.Guidance{}, "Menyatakan Nomor Rute Jalan Nasional", M.NoDuty{}, 311}
  , Sign{"V-10c", Petunjuk{}, "Bentuk Nomor Rute", M.Guidance{}, "Menyatakan Nomor Rute Jalan Provinsi", M.NoDuty{}, 312}
  , Sign{"V-10d", Petunjuk{}, "Bentuk Nomor Rute", M.Guidance{}, "Menyatakan Nomor Rute Jalan Kabupaten", M.NoDuty{}, 313}
  , Sign{"V-10e", Petunjuk{}, "Bentuk Nomor Rute", M.Guidance{}, "Menyatakan Nomor Rute Jalan Kota", M.NoDuty{}, 314}
  , Sign{"VI-1a", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Gerakan Belok Kiri", M.NoDuty{}, 315}
  , Sign{"VI-1b", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Gerakan Belok Kanan", M.NoDuty{}, 316}
  , Sign{"VI-1c", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kiri dan Kanan", M.NoDuty{}, 317}
  , Sign{"VI-1d", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kiri dan Kanan", M.NoDuty{}, 318}
  , Sign{"VI-1e", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kiri", M.NoDuty{}, 319}
  , Sign{"VI-1f", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Badan Jalan di Bagian Kanan", M.NoDuty{}, 320}
  , Sign{"VI-1g", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kiri", M.NoDuty{}, 321}
  , Sign{"VI-1h", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pelebaran Badan Jalan di Bagian Kanan", M.NoDuty{}, 322}
  , Sign{"VI-1i", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pengurangan Lajur Kiri", M.NoDuty{}, 323}
  , Sign{"VI-1j", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Pengurangan Lajur Kanan", M.NoDuty{}, 324}
  , Sign{"VI-1k", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penambahan Lajur Kiri", M.NoDuty{}, 325}
  , Sign{"VI-1l", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penambahan Lajur Kanan", M.NoDuty{}, 326}
  , Sign{"VI-1m", PeringatanSementara{}, "Rambu Peringatan Sementara Perubahan Kondisi Alinyemen Horizontal", M.Warning{}, "Peringatan Penyempitan Bagan Jalinan Jalan Tertentu", M.NoDuty{}, 327}
  , Sign{"VI-2a", PeringatanSementara{}, "Rambu Peringatan Sementara Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Permukaan Jalan yang Licin", M.NoDuty{}, 328}
  , Sign{"VI-2b", PeringatanSementara{}, "Rambu Peringatan Sementara Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Bagian Tepi Jalan yang Tidak Sama Tinggi dengan Badan Jalan", M.NoDuty{}, 329}
  , Sign{"VI-2c", PeringatanSementara{}, "Rambu Peringatan Sementara Kondisi Jalan yang Berbahaya", M.Warning{}, "Peringatan Lontaran Kerikil", M.NoDuty{}, 330}
  , Sign{"VI-3a", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Awal Rintangan pada Sisi Kiri Jalan", M.NoDuty{}, 331}
  , Sign{"VI-3b", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Awal Rintangan pada Sisi Kanan Jalan", M.NoDuty{}, 332}
  , Sign{"VI-3c", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Akhir Rintangan pada Sisi Kiri Jalan", M.NoDuty{}, 333}
  , Sign{"VI-3d", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Akhir Rintangan pada Sisi Kanan Jalan", M.NoDuty{}, 334}
  , Sign{"VI-3e", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Awal Rintangan yang Memisahkan Lajur", M.NoDuty{}, 335}
  , Sign{"VI-3f", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Akhir Rintangan yang Memisahkan Lajur", M.NoDuty{}, 336}
  , Sign{"VI-3g", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Awal Rintangan yang Memisahkan Jalur", M.NoDuty{}, 337}
  , Sign{"VI-3h", PeringatanSementara{}, "Rambu Peringatan Sementara Rintangan di Jalan", M.Warning{}, "Peringatan Bagian Akhir Rintangan yang Memisahkan Jalur", M.NoDuty{}, 338}
  , Sign{"VI-4a", PeringatanSementara{}, "Rambu Peringatan Sementara Lainnya", M.Warning{}, "Peringatan yang Ditegaskan Penjelasan Jenis Peringatan dengan Menggunakan Papan Tambahan", M.NoDuty{}, 339}
  , Sign{"VI-4b", PeringatanSementara{}, "Rambu Peringatan Sementara Lainnya", M.Warning{}, "Peringatan Pekerjaan di Jalan", M.NoDuty{}, 340}
  , Sign{"VI-4c", PeringatanSementara{}, "Rambu Peringatan Sementara Lainnya", M.Warning{}, "Peringatan Tinggi Ruang Bebas (... m)", M.NoDuty{}, 341}
  , Sign{"VI-4d", PeringatanSementara{}, "Rambu Peringatan Sementara Lainnya", M.Warning{}, "Peringatan Lebar Ruang Bebas (... m)", M.NoDuty{}, 342}
  , Sign{"VI-4e", PeringatanSementara{}, "Rambu Peringatan Sementara Lainnya", M.Warning{}, "Peringatan Lalu Lintas Dua Arah", M.NoDuty{}, 343}
  , Sign{"VI-4f", PeringatanSementara{}, "Rambu Peringatan Sementara Lainnya", M.Warning{}, "Peringatan Pengaturan Lalu Lintas oleh Petugas; Peringatan Pelaksanaan Inspeksi di Jalan; Peringatan Pelaksanaan Survey di Jalan", M.NoDuty{}, 344}
  , Sign{"VI-6a", PeringatanSementara{}, "Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis Sementara", M.Warning{}, "Peringatan yang Menerangkan bahwa Lokasi Kritis Berjarak 450 m dari Lokasi Rambu", M.NoDuty{}, 345}
  , Sign{"VI-6b", PeringatanSementara{}, "Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis Sementara", M.Warning{}, "Peringatan yang Menerangkan bahwa Lokasi Kritis Berjarak 300 m dari Lokasi Rambu", M.NoDuty{}, 346}
  , Sign{"VI-6c", PeringatanSementara{}, "Rambu Keterangan Tambahan tentang Jarak Lokasi Kritis Sementara", M.Warning{}, "Peringatan yang Menerangkan bahwa Lokasi Kritis Berjarak 150 m dari Lokasi Rambu", M.NoDuty{}, 347}
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
        case Sign{code, table, group, family, meaning, duty, ordinal}:
          U32.add(Bool.to_u32(same_table(t, table)), count_table(t, tl))

def count_family(+f: M.Sign, xs: List<&2, Sign>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> tl:
      match h:
        case Sign{code, table, group, family, meaning, duty, ordinal}:
          U32.add(Bool.to_u32(same_family(f, family)), count_family(f, tl))

def count_group(+g: String, xs: List<&2, Sign>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> tl:
      match h:
        case Sign{code, table, +group, family, meaning, duty, ordinal}:
          U32.add(Bool.to_u32(String.eq(g, group)), count_group(g, tl))

# Ordinals run 1, 2, 3 ... without a gap, in catalogue order.
def numbered(xs: List<&2, Sign>, +expected: U32) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> tl:
      match h:
        case Sign{code, table, group, family, meaning, duty, ordinal}:
          Bool.and(U32.is_eq(ordinal, expected), numbered(tl, U32.add(expected, 1)))

def all_meaningful(xs: List<&2, Sign>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> tl:
      match h:
        case Sign{code, table, group, family, meaning, duty, ordinal}:
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
        case Sign{code, +table, group, +family, meaning, duty, ordinal}:
          Bool.and(table_family_ok(table, family), all_family_ok(tl))

def supplements_numbered(xs: List<&2, Supplement>, +expected: U32) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> tl:
      match h:
        case Supplement{group, meaning, ordinal}:
          Bool.and(U32.is_eq(ordinal, expected), supplements_numbered(tl, U32.add(expected, 1)))

# ---------------------------------------------------------------------------
# What a posted sign requires
# ---------------------------------------------------------------------------

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

def choose_duty(same: Bool, +found: M.Duty, fallback: M.Duty) -> M.Duty:
  match same:
    case True{}:
      found
    case False{}:
      fallback

# A sign with no duty returns NoDuty.
def duty_of(+code: String, xs: List<&2, Sign>) -> M.Duty:
  match xs:
    case Nil{}:
      M.NoDuty{}
    case h <> tl:
      match h:
        case Sign{+hc, table, group, family, meaning, +duty, ordinal}:
          choose_duty(String.eq(code, hc), duty, duty_of(code, tl))

# The duty a game posts when it places a sign with this code.
def posted(+code: String) -> M.Duty:
  duty_of(code, signs())

def is_no_duty(d: M.Duty) -> Bool:
  match d:
    case M.NoDuty{}:
      True{}
    case _:
      False{}

def count_duties(xs: List<&2, Sign>) -> U32:
  match xs:
    case Nil{}:
      0
    case h <> tl:
      match h:
        case Sign{code, table, group, family, meaning, +duty, ordinal}:
          U32.add(Bool.to_u32(Bool.not(is_no_duty(duty))), count_duties(tl))

def duty_count() -> U32:
  count_duties(signs())

def binding_duty_if(binds: Bool, duty: M.Duty) -> Bool:
  match binds:
    case True{}:
      Bool.not(is_no_duty(duty))
    case False{}:
      is_no_duty(duty)

def every_binding_sign_posts_a_duty(xs: List<&2, Sign>) -> Bool:
  match xs:
    case Nil{}:
      True{}
    case h <> tl:
      match h:
        case Sign{code, table, group, +family, meaning, +duty, ordinal}:
          Bool.and(binding_duty_if(binds_driver(family), duty), every_binding_sign_posts_a_duty(tl))

# ---------------------------------------------------------------------------
# Reading a duty
# ---------------------------------------------------------------------------

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

