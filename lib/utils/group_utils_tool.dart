import 'package:open_chat/utils/client_utils.dart';
import 'package:sqlite3/sqlite3.dart';

import '../store/client_data.dart';

List<int> loadGroupId() {
  try {
    int userId = clientData.user!.id;
    final db = sqlite3.open('./lib/store/db/$userId.db');
    final ResultSet resultSet =
        db.select('SELECT contact_id FROM contact WHERE contact_id>599999999');
    List<int> groupIdList = [];
    if (resultSet.isNotEmpty) {
      for (final Row row in resultSet) {
        groupIdList.add(row['contact_id']);
      }
    }
    logger.d('[group application] 获取群组列表:${groupIdList.toString()}');
    return groupIdList;
  } catch (e) {
    return [];
  }
}
