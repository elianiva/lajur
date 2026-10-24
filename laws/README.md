# Source statutes

Unmodified PDFs. The model in `bend/` cites these by instrument and article, so a claim in the code can always be traced to a page here.

## Manifest

| File | Instrument | Pages | Retrieved |
| --- | --- | --- | --- |
| `uu-22-2009-lalu-lintas-dan-angkutan-jalan.pdf` | UU 22/2009, Lalu Lintas dan Angkutan Jalan | 203 | 2026-10-24 |
| `pp-30-2021-penyelenggaraan-llaj.pdf` | PP 30/2021, Penyelenggaraan Bidang LLAJ | 57 | 2026-10-24 |
| `pp-37-2017-keselamatan-llaj.pdf` | PP 37/2017, Keselamatan LLAJ | 33 | 2026-10-24 |
| `pp-79-2013-jaringan-llaj.pdf` | PP 79/2013, Jaringan LLAJ | 97 | 2026-10-24 |
| `pm-13-2014-rambu-lalu-lintas.pdf` | PM 13/2014, Rambu Lalu Lintas (with attachments) | 193 | 2026-10-24 |
| `pm-111-2015-batas-kecepatan.pdf` | PM 111/2015, Tata Cara Penetapan Batas Kecepatan | 27 | 2026-10-24 |
| `perpol-5-2021-sim.pdf` | Perpol 5/2021, Penerbitan dan Penandaan SIM | 34 | 2026-10-24 |
| `uu-28-2014-hak-cipta.pdf` | UU 28/2014, Hak Cipta (Pasal 42 only) | 63 | 2026-10-24 |

## Checksums

```text
f532e5d239ab2acca1aeae14d4aaf10548f0a4f863112c4dc73bc0b89de8c412  perpol-5-2021-sim.pdf
1e5330831c272c55c6fc8476dc469a5b46abfd027d6e28c05d64e7cb46a2150e  pm-111-2015-batas-kecepatan.pdf
2e0a113c5894478e470057f234793502cd36c2ad1a3aa1758c3bb5f0687d807d  pm-13-2014-rambu-lalu-lintas.pdf
3232a2918d7c0e5df21d0e9cc217b1bb7dd888482ba8dc5008db185f713afcee  pp-30-2021-penyelenggaraan-llaj.pdf
a4bb6913f6e1cef56c7c1c3eed9c4278a6e4b86269f076265d62b6812fb786a0  pp-37-2017-keselamatan-llaj.pdf
efdb46f53920be9b275229a91a70f0d09bdef49c0369ca4e16728afd5bb96857  pp-79-2013-jaringan-llaj.pdf
85ae58c2d6d60e3de6479781dbfdf6c24932d26f74606cd2f1931508f51f8da9  uu-22-2009-lalu-lintas-dan-angkutan-jalan.pdf
040a5f8925ab9630726181e20161ce4ec8855bdf561e838590cbc6a075287d9e  uu-28-2014-hak-cipta.pdf
```

Verify with:

```sh
cd laws && sha256sum -c <(sed -n '/^```text$/,/^```$/p' README.md | grep -E '^[0-9a-f]{64}')
```

## Where each file came from

`peraturan.go.id` and `peraturan.bpk.go.id` block automated downloads, so the files come from the ministry and police repositories that serve the same scans.

| File | Source |
| --- | --- |
| UU 22/2009 | Korlantas regulation repository: `https://k3i.korlantas.polri.go.id/api/web/uploads/regulation_doc/UNDANG-UNDANG-NOMOR-22-TAHUN-2009-TENTANG-LALU-LINTAS-DAN-ANGKUTAN-JALAN.pdf` |
| PP 30/2021 | JDIH Kemenhub detail page, data key `IKrvlmyF8eHKwY555SrDs48MS8ISgeb9I4a8cGE4ZRI54eajUUNVg4E4a8c0i8p3Wj8hfKalFehST4Z7SkAllxJd4pBxNY3WFql4pCCjgLm3xG6LCV4DnqLgE8PqlbltC3vT9MRTIB7FKhVGgrDpkhttCp` |
| PP 37/2017 | JDIH Kemenhub detail page, data key `HMILmK9L5iKKlf8s85K7Hu8bLPbJRgsBa4Et6LDCLHXt4jrvv86zR2J48d3lGN9o8J4vQhjRgl6Iw48aSePCzJ1Z49Y103KN5Uu8Rm9oizgp5t4hDuB9Ulz11LBgZrARxvzgDiy1ghWYmclFMj2HMWDIYb` |
| PP 79/2013 | JDIH Kemenhub detail page, data key `73PFXCaniHnEgn2bgpvwze8QfqaDuIGeX4OcfblThUUZ4fY1Y8rAaRQ48ahdduPz0e4kqVqR51ZlD4p6pbWky6ZI49cxXyTj6F34OXVWWlyG6X78iDaHxxLV7KyxVYUHj6ka1AHWqJBtcXzAlqoYQJ8zXw` |
| PM 13/2014 | JDIH Kemenhub detail page, data key `4mnzQ5shFbh0njaP06suoe4uWDGmp6MYW4OXUtxoTIMm48blt9kwjZ44EvtdF0suAw8goSvgFNbQO8Qh8SKbSRiq4KBo7fnYoqu4KAW8RXNA5B4ZPDBryqvTnDN4AT8L3PYXKCIggf8FJ898N4cHI6YzjS` |
| PM 111/2015 | JDIH Kemenhub detail page, data key `05G3OMsYHZy1KUd8c5eOE38VyYryVUJ0c8m6xDzSKTZ38cNcwq2NzfP4uWDwzgqcgz4ed4MRKP4tx4OVxjOjVbT44pH7luwUlV38W3hxIco9HU91PMr0iw8bU5cTvSFZ5jxo1rD6yylVzFwK1PTJOWYOYB` |
| Perpol 5/2021 | Wayback snapshot of `korlantas.polri.go.id/wp-content/uploads/2021/03/PERPOL-NO-5-TH-2021-TTG-PENERBITAN-DAN-PENANDAAN-SIM.pdf`, timestamp 20260923210630 |
| UU 28/2014 | `learning.hukumonline.com/wp-content/uploads/2020/10/UU_NO_28_2014.pdf`; canonical record at `peraturan.go.id/id/uu-no-28-tahun-2014` |

Detail pages resolve at `https://jdih.dephub.go.id/peraturan/detail?data=<data key>`.

## Checks performed

Each file was opened and its first page read:

| File | First page confirms |
| --- | --- |
| UU 22/2009 | "UNDANG-UNDANG REPUBLIK INDONESIA NOMOR 22 TAHUN 2009 TENTANG LALU LINTAS DAN ANGKUTAN JALAN" |
| PP 30/2021 | "PERATURAN PEMERINTAH REPUBLIK INDONESIA NOMOR 30 TAHUN 2021" |
| PP 37/2017 | "PERATURAN PEMERINTAH REPUBLIK INDONESIA NOMOR 37 TAHUN 2017" |
| PP 79/2013 | "NOMOR 79 TAHUN 2013 TENTANG JARINGAN LALU LINTAS DAN ANGKUTAN JALAN" |
| PM 13/2014 | "NOMOR PM 13 TAHUN 2014 TENTANG RAMBU LALU LINTAS" |
| PM 111/2015 | Scanned page. Rendered and read: "NOMOR PM 111 TAHUN 2015", "TATA CARA PENETAPAN BATAS KECEPATAN" |
| Perpol 5/2021 | "NOMOR 5 TAHUN 2021 TENTANG PENERBITAN DAN PENANDAAN SURAT IZIN MENGEMUDI" |
| UU 28/2014 | "UNDANG-UNDANG REPUBLIK INDONESIA NOMOR 28 TAHUN 2014 TENTANG HAK CIPTA" |

## To add

- **Perpol 2/2023**, which amends Perpol 5/2021 on SIM issuance.
- **The third amendment to UU 22/2009**, once enacted. Expected 2027.
- **Provincial and municipal regulations** for the jurisdictions the game covers.
