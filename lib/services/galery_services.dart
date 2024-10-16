import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

const String baseUrl =
    'https://praktikum-cpanel-unbin.com/kelompok_ojan/school_apps_api/galery_api.php';

// Fetch all gallery data
Future<List<dynamic>> fetchGaleryData() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/galery_api.php'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedResponse = json.decode(response.body);
      if (decodedResponse['status'] == 'sukses') {
        List<dynamic> data = decodedResponse['data'];

        // Perbaiki URL gambar
        return data.map((item) {
          if (item is Map && item.containsKey('foto_galery')) {
            item['foto_galery'] = '$baseUrl/uploads/${item['foto_galery']}';
          }
          return item;
        }).toList();
      } else {
        throw Exception(decodedResponse['pesan']);
      }
    } else {
      throw Exception('Gagal memuat data galeri: ${response.statusCode}');
    }
  } catch (e) {
    print('Error mengambil data galeri: $e');
    rethrow;
  }
}

// Add new gallery item
Future<bool> addGaleryItem(Map<String, dynamic> newItem) async {
  var uri = Uri.parse('$baseUrl?action=add');
  var request = http.MultipartRequest('POST', uri);

  request.fields['judul_galery'] = newItem['judul_galery'];
  request.fields['isi_galery'] = newItem['isi_galery'];
  request.fields['tgl_post_galery'] = newItem['tgl_post_galery'];
  request.fields['status_galery'] = newItem['status_galery'];
  request.fields['kd_petugas'] = newItem['kd_petugas'];

  if (newItem['foto_galery'] != null) {
    if (kIsWeb) {
      // Untuk web
      Uint8List data = await newItem['foto_galery'].readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'foto_galery',
        data,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpeg'),
      ));
    } else {
      // Untuk mobile
      request.files.add(await http.MultipartFile.fromPath(
        'foto_galery',
        newItem['foto_galery'].path,
      ));
    }
  }

  try {
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    print("Respons dari server: $responseBody"); // Logging
    var jsonResponse = json.decode(responseBody);
    return jsonResponse['status'] == 'sukses';
  } catch (e) {
    print("Error saat mengirim request: $e"); // Logging
    return false;
  }
}

// Edit gallery item
Future<bool> editGaleryItem(Map<String, dynamic> updatedItem) async {
  var request =
      http.MultipartRequest('POST', Uri.parse('$baseUrl?action=edit'));

  request.fields['kd_galery'] = updatedItem['kd_galery'];
  request.fields['judul_galery'] = updatedItem['judul_galery'];
  request.fields['isi_galery'] = updatedItem['isi_galery'];
  request.fields['tgl_post_galery'] = updatedItem['tgl_post_galery'];
  request.fields['status_galery'] = updatedItem['status_galery'];
  request.fields['kd_petugas'] = updatedItem['kd_petugas'];

  if (updatedItem['foto_galery'] != null &&
      updatedItem['foto_galery'] is File) {
    var file = updatedItem['foto_galery'];
    var stream = http.ByteStream(file.openRead());
    var length = await file.length();
    var multipartFile = http.MultipartFile(
      'foto_galery',
      stream,
      length,
      filename: path.basename(file.path),
    );
    request.files.add(multipartFile);
  }

  var response = await request.send();
  var responseBody = await response.stream.bytesToString();
  var jsonResponse = json.decode(responseBody);
  return jsonResponse['status'] == 'sukses';
}

// Delete gallery item
Future<bool> deleteGaleryItem(String kdGalery) async {
  final url = '$baseUrl?action=delete&kd_galery=$kdGalery';
  final response = await http.post(Uri.parse(url));

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(response.body);
    return jsonResponse['status'] == 'sukses';
  } else {
    throw Exception('Gagal menghapus item galeri');
  }
}
