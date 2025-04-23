import 'dart:math';

class MockUtil {
  static String getRandomString({int length = 8}) {
    final random = Random();
    const availableChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    final randomString = List.generate(length,
            (index) => availableChars[random.nextInt(availableChars.length)])
        .join();
    return randomString;
  }

  static String generateRandomSentence([int length = 20]) {
    final random = Random();
    final isChinese = random.nextBool();
    return isChinese
        ? _generateChineseSentence(length)
        : _generateEnglishSentence(length);
  }

  static String _generateChineseSentence(int targetLength) {
    final random = Random();
    final components = <String>[];

    const time = ['今天', '昨天', '早上', '下午', '上周', '最近'];
    const subjects = ['我', '你', '他', '老师', '学生', '医生'];
    const verbs = ['去', '吃', '学习', '读', '写', '跑步'];
    const objects = ['学校', '饭', '书', '公园', '电影', '电脑'];
    const places = ['图书馆', '家', '学校', '公司', '公园'];
    const adjectives = ['美丽的', '快乐的', '忙碌的', '有趣的'];
    const connectors = ['然后', '接着', '之后', '而且'];

    String buildClause() {
      final clause = StringBuffer();
      if (random.nextBool()) {
        clause.write('${time[random.nextInt(time.length)]}，');
      }
      if (random.nextBool()) {
        clause.write(adjectives[random.nextInt(adjectives.length)]);
      }
      clause
        ..write(subjects[random.nextInt(subjects.length)])
        ..write(places[random.nextInt(places.length)])
        ..write(verbs[random.nextInt(verbs.length)])
        ..write(objects[random.nextInt(objects.length)]);
      return clause.toString();
    }

    components.add(buildClause());

    while (components.join('，').length < targetLength) {
      components.add(
          '${connectors[random.nextInt(connectors.length)]}${buildClause()}');
    }

    final sentence = '${components.join('，')}。';
    return _adjustLength(sentence, targetLength);
  }

  static String _generateEnglishSentence(int targetLength) {
    final random = Random();
    final components = <String>[];

    const subjects = ['The cat', 'A student', 'My friend', 'The teacher'];
    const verbs = ['reads', 'eats', 'writes', 'plays', 'studies'];
    const objects = ['a book', 'the food', 'an article', 'games'];
    const adverbs = ['carefully', 'happily', 'quickly', 'quietly'];
    const connectors = ['then', 'after that', 'moreover', 'and'];

    String buildClause() {
      return '${subjects[random.nextInt(subjects.length)]} '
          '${verbs[random.nextInt(verbs.length)]} '
          '${objects[random.nextInt(objects.length)]} '
          '${adverbs[random.nextInt(adverbs.length)]}';
    }

    components.add(buildClause());

    while (components.join(', ').length < targetLength) {
      components.add(
          '${connectors[random.nextInt(connectors.length)]} ${buildClause()}');
    }

    final sentence =
        '${components.join(', ').replaceRange(0, 1, components.first[0].toUpperCase())}.';
    return _adjustLength(sentence, targetLength);
  }

  static String _adjustLength(String sentence, int targetLength) {
    if (sentence.length <= targetLength) return sentence;

    final cutoff = sentence.lastIndexOf(RegExp(r'[。,.]'), targetLength);
    return cutoff != -1
        ? sentence.substring(0, cutoff + 1)
        : sentence.substring(0, targetLength);
  }
}
