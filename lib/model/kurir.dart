class Kurir {
  final String id;
  final String nama;
  final String email;
  final String telp;

  Kurir({
    required this.id,
    required this.nama,
    required this.email,
    required this.telp,
  });

  factory Kurir.fromJson(Map<String, dynamic> json) {
    return Kurir(
      id: json['id_pegawai'],
      nama: json['nama_pegawai'],
      email: json['email_pegawai'],
      telp: json['telp_pegawai'],
    );
  }
}
