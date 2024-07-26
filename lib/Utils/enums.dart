import 'package:tuple/tuple.dart';

enum ActiveThemeMode { system, light, dark }

enum MultiWindowType { Main, Setting, Unknown }

extension Index on int {
  MultiWindowType get windowType {
    switch (this) {
      case 0:
        return MultiWindowType.Main;
      case 1:
        return MultiWindowType.Setting;
      default:
        return MultiWindowType.Unknown;
    }
  }
}

enum DoubleTapAction {
  none('none', '无操作'),
  like('like', '喜欢'),
  recommend('recommend', '推荐'),
  download('download', '下载当前图片'),
  downloadAll('downloadAll', '下载所有图片'),
  copyLink('copyLink', '复制帖子链接');

  const DoubleTapAction(this.key, this.label);

  final String key;
  final String label;
}

enum DownloadSuccessAction {
  none('none', '无操作'),
  unlike('unlike', '取消喜欢'),
  unrecommend('unrecommend', '取消推荐');

  const DownloadSuccessAction(this.key, this.label);

  final String key;
  final String label;
}

extension DoubleTapEnumExtension on DoubleTapAction {
  List<Tuple2<String, DoubleTapAction>> get tuples {
    return DoubleTapAction.values.map((e) => Tuple2(e.label, e)).toList();
  }
}

extension DownloadSuccessEnumExtension on DownloadSuccessAction {
  List<Tuple2<String, DownloadSuccessAction>> get tuples {
    return DownloadSuccessAction.values.map((e) => Tuple2(e.label, e)).toList();
  }
}