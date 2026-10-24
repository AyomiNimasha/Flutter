import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../cloud_sync/api_client.dart';

class CertificateService {
  CertificateService(this.api);
  final ApiClient api;
  Future<File> download(String petId) async {
    // API IDs are UUIDs. Validation also prevents writing outside this folder.
    if (!RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(petId)) {
      throw ArgumentError('Invalid pet ID');
    }
    final bytes = await api.certificate(petId);
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'pawshots-$petId.pdf'));
    return file.writeAsBytes(bytes, flush: true);
  }

  Future<void> share(File file) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }
}
