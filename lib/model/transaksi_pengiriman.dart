class TransaksiPengiriman {
  final int id;
  final String status;
  final String tanggal;
  final String alamat;
  final String pembeli;
  final List<BarangPengiriman> barangs;

  TransaksiPengiriman({
    required this.id,
    required this.status,
    required this.tanggal,
    required this.alamat,
    required this.pembeli,
    required this.barangs,
  });

  factory TransaksiPengiriman.fromJson(Map<String, dynamic> json) {
    return TransaksiPengiriman(
      id: json['id_transaksi'],
      status: json['status_transaksi'],
      tanggal: json['tanggal_pesan'] ?? '',
      alamat: json['alamat_pengiriman'],
      pembeli: json['pembeli'] != null ? json['pembeli']['nama_pembeli'] : 'Tanpa Pembeli',
      barangs: (json['detail_transaksi'] as List)
        .where((item) => item['barang'] != null)
        .map((item) => BarangPengiriman.fromJson(item['barang']))
        .toList(),

    );
  }
}

class BarangPengiriman {
  final String nama;
  final int harga;
  final String? gambar;

  BarangPengiriman({
    required this.nama,
    required this.harga,
    this.gambar,
  });

  factory BarangPengiriman.fromJson(Map<String, dynamic> json) {
    return BarangPengiriman(
      nama: json['nama_barang'],
      harga: json['harga_barang'].toInt(),
      gambar: (json.containsKey('gambar') && (json['gambar'] as List).isNotEmpty)
          ? json['gambar'][0]['directory']
          : null,
    );
  }
}
