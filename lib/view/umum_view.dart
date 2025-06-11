// lib/view/umum_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_application_p3l/services/home_service.dart';
import 'package:flutter_application_p3l/view/detail_barang_view.dart';
import 'package:flutter_application_p3l/view/login.dart';
import 'package:intl/intl.dart';

final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);
enum SortOption { none, priceAsc, priceDesc }

class UmumView extends StatefulWidget {
  const UmumView({super.key});

  @override
  State<UmumView> createState() => _UmumViewState();
}

class _UmumViewState extends State<UmumView> {
  List<dynamic> kategori = [];
  List<dynamic> _allBarang = [];
  List<dynamic> _filteredBarang = [];
  final TextEditingController _searchController = TextEditingController();
  int? _selectedKategoriId;
  SortOption _currentSortOption = SortOption.none;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await loadHomeData();
    _searchController.addListener(_filterAndSortBarang);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadHomeData() async {
    setState(() => _isLoading = true);
    try {
      final kategoriRes = await HomeService.fetchKategori();
      final barangRes = await HomeService.fetchBarang();
      if (mounted) {
        setState(() {
          kategori = kategoriRes;
          _allBarang = barangRes;
          _filteredBarang = barangRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error loading home data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  void _filterAndSortBarang() {
    List<dynamic> tempBarang = List.from(_allBarang);

    if (_searchController.text.isNotEmpty) {
      String query = _searchController.text.toLowerCase();
      tempBarang = tempBarang.where((barang) {
        return barang['nama_barang'].toString().toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedKategoriId != null) {
      tempBarang = tempBarang.where((barang) {
        return barang['id_kategori'] == _selectedKategoriId;
      }).toList();
    }

    switch (_currentSortOption) {
      case SortOption.priceAsc:
        tempBarang.sort((a, b) => a['harga_barang'].compareTo(b['harga_barang']));
        break;
      case SortOption.priceDesc:
        tempBarang.sort((a, b) => b['harga_barang'].compareTo(a['harga_barang']));
        break;
      case SortOption.none:
        break;
    }

    setState(() {
      _filteredBarang = tempBarang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadHomeData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // TAMBAHKAN KEMBALI: Widget untuk carousel banner
                  AspectRatio(
                    aspectRatio: 16 / 7, // Sesuaikan rasio agar pas
                    child: PageView(
                      children: [
                        _carouselItem('images/banner1.jpg'),
                        _carouselItem('images/banner2.jpg'),
                        _carouselItem('images/banner3.jpg'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildKategoriList(),
                  const SizedBox(height: 20),
                  _buildSortButtons(),
                  const SizedBox(height: 20),
                  const Text('Rekomendasi Untuk Anda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildBarangGrid(),
                ],
              ),
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF005E34),
      title: _buildSearchBar(),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
              );
            },
            child: const Text(
              'Login',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari di Reusemart...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => _searchController.clear(),
                )
              : null,
        ),
      ),
    );
  }

  // TAMBAHKAN KEMBALI: Fungsi helper untuk item carousel
  Widget _carouselItem(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  Widget _buildSortButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_upward),
          label: const Text("Harga Terendah"),
          onPressed: () {
            setState(() => _currentSortOption = SortOption.priceAsc);
            _filterAndSortBarang();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: _currentSortOption == SortOption.priceAsc ? Colors.white : const Color(0xFF005E34),
            backgroundColor: _currentSortOption == SortOption.priceAsc ? const Color(0xFF005E34) : Colors.transparent,
            side: const BorderSide(color: Color(0xFF005E34)),
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_downward),
          label: const Text("Harga Tertinggi"),
          onPressed: () {
            setState(() => _currentSortOption = SortOption.priceDesc);
            _filterAndSortBarang();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: _currentSortOption == SortOption.priceDesc ? Colors.white : const Color(0xFF005E34),
            backgroundColor: _currentSortOption == SortOption.priceDesc ? const Color(0xFF005E34) : Colors.transparent,
            side: const BorderSide(color: Color(0xFF005E34)),
          ),
        ),
      ],
    );
  }

  Widget _buildKategoriList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: kategori.length,
        itemBuilder: (context, index) {
          final item = kategori[index];
          final imageUrl = 'http://10.0.2.2:8000/images/${Uri.encodeComponent(item['gambar'])}';
          final bool isSelected = _selectedKategoriId == item['id_kategori'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedKategoriId = isSelected ? null : item['id_kategori'];
              });
              _filterAndSortBarang();
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF005E34) : const Color(0xFFE1DDD2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.green.shade700,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: Image.network(imageUrl, fit: BoxFit.contain)),
                  const SizedBox(height: 5),
                  Text(
                    item['kategori'],
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarangGrid() {
    if (_filteredBarang.isEmpty && !_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Barang tidak ditemukan.\nCoba kata kunci atau filter lain.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredBarang.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        final item = _filteredBarang[index];
        final imageUrl = (item['images'] != null && (item['images'] as List).isNotEmpty)
            ? 'http://10.0.2.2:8000/gambarBarang/${Uri.encodeComponent(item['images'][0]['directory'])}'
            : 'https://via.placeholder.com/160?text=No+Image';
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailBarangView(barang: item),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nama_barang'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(item['harga_barang']),
                        style: const TextStyle(
                          color: Color(0xFF005E34),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}