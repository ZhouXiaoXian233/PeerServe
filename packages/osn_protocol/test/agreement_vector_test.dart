import 'dart:convert';
import 'dart:io';

import 'package:osn_protocol/osn_protocol.dart';
import 'package:test/test.dart';

Directory repoRoot() {
  var directory = Directory.current;
  while (true) {
    if (Directory('${directory.path}/protocol/test-vectors').existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('找不到仓库根目录（protocol/test-vectors）');
    }
    directory = parent;
  }
}

void main() {
  test('固定 Agreement 向量可复算规范化 JSON', () async {
    final file = File(
      '${repoRoot().path}/protocol/test-vectors/agreement/agreement_v1.json',
    );
    final document =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final agreement = Agreement.fromJson(document['agreement']);

    expect(agreement.toJson(), document['agreement']);
    expect(canonicalize(agreement.toJson()), document['canonical_json']);
  });
}
