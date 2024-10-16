import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Tambahkan import ini untuk menggunakan File
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/galery_services.dart';

class GaleryScreen extends StatefulWidget {
  const GaleryScreen({super.key});

  @override
  _GaleryScreenState createState() => _GaleryScreenState();
}

class _GaleryScreenState extends State<GaleryScreen> {
  List<dynamic> galeryData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGaleryData();
  }

  Future<void> fetchGaleryData() async {
    setState(() {
      isLoading = true;
    });

    final response = await http.get(Uri.parse(
        'https://praktikum-cpanel-unbin.com/kelompok_ojan/tugas_mpper4/galery.php'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        galeryData = jsonData['data'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data galeri')),
      );
    }
  }

  void showGaleryForm({Map<String, dynamic>? item}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GaleryFormDialog(
          item: item,
          onSave: (newItem) {
            if (item == null) {
              addGaleryItem(newItem);
            } else {
              editGaleryItem(newItem);
            }
          },
        );
      },
    );
  }

  Future<void> addGaleryItem(Map<String, dynamic> newItem) async {
    final url = Uri.parse(
        'https://praktikum-cpanel-unbin.com/kelompok_ojan/tugas_mpper4/galery.php');
    var request = http.MultipartRequest('POST', url);

    request.fields['judul_galery'] = newItem['judul_galery'];
    request.fields['isi_galery'] = newItem['isi_galery'];
    request.fields['tgl_post_galery'] = newItem['tgl_post_galery'];
    request.fields['status_galery'] = newItem['status_galery'];
    request.fields['kd_petugas'] = newItem['kd_petugas'];

    if (newItem['foto_galery'] != null) {
      request.files.add(await http.MultipartFile.fromPath(
          'foto_galery', newItem['foto_galery'].path));
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil menambahkan item galeri')),
      );
      fetchGaleryData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menambahkan item galeri')),
      );
    }
  }

  Future<void> editGaleryItem(Map<String, dynamic> updatedItem) async {
    final url = Uri.parse(
        'https://praktikum-cpanel-unbin.com/kelompok_ojan/tugas_mpper4/galery.php');
    var request = http.MultipartRequest('POST', url);

    request.fields['action'] = 'edit';
    request.fields['kd_galery'] = updatedItem['kd_galery'];
    request.fields['judul_galery'] = updatedItem['judul_galery'];
    request.fields['isi_galery'] = updatedItem['isi_galery'];
    request.fields['tgl_post_galery'] = updatedItem['tgl_post_galery'];
    request.fields['status_galery'] = updatedItem['status_galery'];
    request.fields['kd_petugas'] = updatedItem['kd_petugas'];

    if (updatedItem['foto_galery'] != null &&
        updatedItem['foto_galery'] is File) {
      request.files.add(await http.MultipartFile.fromPath(
          'foto_galery', updatedItem['foto_galery'].path));
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil mengubah item galeri')),
      );
      fetchGaleryData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengubah item galeri')),
      );
    }
  }

  Future<void> deleteGaleryItem(String kdGalery) async {
    final url = Uri.parse(
        'https://praktikum-cpanel-unbin.com/kelompok_ojan/tugas_mpper4/galery.php?kd_galery=$kdGalery');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'sukses') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil menghapus item galeri')),
        );
        fetchGaleryData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Gagal menghapus item galeri: ${jsonResponse['message'] ?? 'Terjadi kesalahan'}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal menghapus item galeri: Kesalahan jaringan')),
      );
    }
  }

  Future<void> _refreshGaleryData() async {
    await fetchGaleryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeri'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshGaleryData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: galeryData.length,
                itemBuilder: (context, index) {
                  final item = galeryData[index];
                  return ListTile(
                    leading: Image.network(
                      'https://praktikum-cpanel-unbin.com/kelompok_ojan/tugas_mpper4/${item['foto_galery']}',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error);
                      },
                    ),
                    title: Text(item['judul_galery']),
                    subtitle: Text(item['isi_galery']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => showGaleryForm(item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Konfirmasi Hapus'),
                                content: const Text(
                                    'Apakah Anda yakin ingin menghapus item ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      deleteGaleryItem(item['kd_galery']);
                                    },
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    onTap: () => showGaleryForm(item: item),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showGaleryForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GaleryFormDialog extends StatefulWidget {
  final Map<String, dynamic>? item;
  final Function(Map<String, dynamic>) onSave;

  const GaleryFormDialog({super.key, this.item, required this.onSave});

  @override
  _GaleryFormDialogState createState() => _GaleryFormDialogState();
}

class _GaleryFormDialogState extends State<GaleryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _isiController;
  late TextEditingController _tglPostController;
  late TextEditingController _statusController;
  late TextEditingController _kdPetugasController;
  dynamic _image;

  @override
  void initState() {
    super.initState();
    _judulController =
        TextEditingController(text: widget.item?['judul_galery'] ?? '');
    _isiController =
        TextEditingController(text: widget.item?['isi_galery'] ?? '');
    _tglPostController = TextEditingController(
        text: widget.item?['tgl_post_galery'] ??
            DateTime.now().toString().split(' ')[0]);
    _statusController =
        TextEditingController(text: widget.item?['status_galery'] ?? '');
    _kdPetugasController =
        TextEditingController(text: widget.item?['kd_petugas'] ?? '');
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    _tglPostController.dispose();
    _statusController.dispose();
    _kdPetugasController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _image = pickedFile;
        } else {
          _image = File(pickedFile.path);
        }
      });
    }
  }

  Widget _buildImagePreview() {
    if (_image != null) {
      if (kIsWeb) {
        return Image.network(_image.path);
      } else {
        return Image.file(_image);
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Tambah Galeri' : 'Edit Galeri',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _isiController,
                decoration: const InputDecoration(
                  labelText: 'Isi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Isi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tglPostController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Post',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                validator: (value) =>
                    value!.isEmpty ? 'Tanggal Post tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _statusController,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Status tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kdPetugasController,
                decoration: const InputDecoration(
                  labelText: 'Kode Petugas',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Kode Petugas tidak boleh kosong' : null,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pilih Gambar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImagePreview(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final newItem = {
                'judul_galery': _judulController.text,
                'isi_galery': _isiController.text,
                'tgl_post_galery': _tglPostController.text,
                'status_galery': _statusController.text,
                'kd_petugas': _kdPetugasController.text,
                if (_image != null) 'foto_galery': _image,
              };

              try {
                print("Mengirim data: $newItem"); // Logging
                bool success = await addGaleryItem(newItem);
                print("Hasil operasi: $success"); // Logging
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data berhasil disimpan')),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menyimpan data')),
                  );
                }
              } catch (e) {
                print("Error saat menyimpan data: $e"); // Logging
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Terjadi kesalahan: $e')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
