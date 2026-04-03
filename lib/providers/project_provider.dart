import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/project.dart';
import '../remote/Api.dart';
import '../remote/service/NerworkService.dart';
import 'pagination_provider.dart';

// 项目分页Provider
final projectProvider = StateNotifierProvider<PaginationNotifier<ProjectArticle>, AsyncValue<List<ProjectArticle>>>((ref) {
  return PaginationNotifier<ProjectArticle>(
    fetchFunction: (page, pageSize)  {
      final req = ProjectListReq(page: page, pageSize: pageSize);
      return NetworkService.get<ProjectListResp>(
        url: req.path,
        fromJsonT: ProjectListResp.fromJson,
      ).getData().then((value) => value.datas);
    },
    defaultPageSize: 8,
    enableCache: true,
  );
});
