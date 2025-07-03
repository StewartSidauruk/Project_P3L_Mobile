class TransaksiPengiriman {
  final int id;
  final String status;
  final String tanggal;
  final String alamat;
  final String pembeli;
  final List<BarangPengiriman> barangs;
  final String nota; // This field seems to be derived from detail_penitipan, but in the context of transaksi_penjualan, it might be extraneous or needs clarification. For now, keep it as it's in your original.

  TransaksiPengiriman({
    required this.id,
    required this.status,
    required this.tanggal,
    required this.alamat,
    required this.pembeli,
    required this.barangs,
    required this.nota,
  });

  factory TransaksiPengiriman.fromJson(Map<String, dynamic> json) {
    // Safely get the nota from detail_transaksi or provide a default
    String fetchedNota = 'N/A'; // Default value
    if (json['detail_transaksi'] is List && (json['detail_transaksi'] as List).isNotEmpty) {
      // Assuming you want the nota from the first detail transaction
      final firstDetail = (json['detail_transaksi'] as List)[0];
      if (firstDetail['nota_transaksi'] is String) {
        fetchedNota = firstDetail['nota_transaksi'];
      }
    }
    return TransaksiPengiriman(
      id: json['id_transaksi'],
      status: json['status_transaksi'],
      tanggal: json['tanggal_pesan'] ?? '',
      alamat: json['alamat_pengiriman'] ?? 'Alamat Tidak Tersedia', // Add null check for alamat
      pembeli: json['pembeli'] != null ? json['pembeli']['nama_pembeli'] : 'Tanpa Pembeli',
      barangs: (json['detail_transaksi'] as List?) // Use nullable list type
          ?.where((item) => item['barang'] != null)
          .map((item) => BarangPengiriman.fromJson(item['barang']))
          .toList() ?? [], // Provide an empty list if null
     nota: fetchedNota, // Use the safely retrieved nota value
    );
  }
}

class BarangPengiriman {
  final String nama;
  final int harga;
  final String? gambar; // This is now correctly nullable

  BarangPengiriman({
    required this.nama,
    required this.harga,
    this.gambar,
  });

factory BarangPengiriman.fromJson(Map<String, dynamic> json) {
    // Access the 'images' array within the 'barang' object
    final List<dynamic>? images = json['images'];
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      imageUrl = "https://projectp3l-production.up.railway.app/gambarBarang/${Uri.encodeComponent(images[0]['directory'])}"; // Prepend base URL
    }

    return BarangPengiriman(
      nama: json['nama_barang'],
      harga: (json['harga_barang'] as num).toInt(), // Cast to num first, then toInt()
      gambar: imageUrl,
    );
  }
}