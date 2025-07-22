import 'dart:io';

import 'package:html/dom.dart' show Element;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

void main() async {
  final urls = await getAllModelUrls();
  // print(await getModel(urls.first));
  final models = await Future.wait(urls.map(getModel));

  final result = '''
import 'package:xml/xml.dart';

XmlElement getProp(XmlElement xml, String name) {
  final result = xml.findElements(name);
  return result.isNotEmpty ? result.first : null;
}

${models.join('\n')}
  ''';

  await File('lib/src/s3_models_generated.dart').writeAsString(result);
}

const baseUrl = 'https://docs.aws.amazon.com/AmazonS3/latest/API';

Future<List<String>> getAllModelUrls() async {
  print('Getting Index.');
  final url = '$baseUrl/API_Types_Amazon_Simple_Storage_Service.html';
  final page = await http.get(Uri.parse(url));
  final document = parse(page.body);
  final urls = document.querySelectorAll('.listitem a');
  return urls
      .map<String>((a) => a.attributes['href']!.substring(2))
      .map((a) => '$baseUrl/$a')
      .toList();
}

Future<String> getModel(String url) async {
  print('Getting: $url.');
  final page = await http.get(Uri.parse(url));
  final document = parse(page.body);

  final name = document.querySelector('h1')!.text;
  final description = document
      .querySelector('#main-col-body p')!
      .text
      .replaceAll(RegExp(r'\s+'), ' ');

  final fields = <FieldSpec>[];
  for (var dt in document.querySelectorAll('dt')) {
    final name = dt.text.trim();
    final spec = parseField(name, dt.nextElementSibling!);
    fields.add(spec);
  }

  final buffer = StringBuffer();
  buffer.writeln('/// $description');
  buffer.writeln('class $name {');

  buffer.writeln('  $name(');
  for (var field in fields) {
    buffer.writeln('      this.${field.dartName},');
  }
  buffer.writeln('  );');
  buffer.writeln('');

  buffer.writeln('  $name.fromXml(XmlElement xml) {');
  for (var field in fields) {
    switch (field.type.name) {
      case 'String':
        buffer.writeln(
            "      ${field.dartName} = getProp(xml, '${field.name}')?.text;");
        break;
      case 'int':
        buffer.writeln(
            "      ${field.dartName} = int.tryParse(getProp(xml, '${field.name}')?.text);");
        break;
      case 'bool':
        buffer.writeln(
            "      ${field.dartName} = getProp(xml, '${field.name}')?.text?.toUpperCase() == 'TRUE';");
        break;
      case 'DateTime':
        buffer.writeln(
            "      ${field.dartName} = DateTime.parse(getProp(xml, '${field.name}')?.text);");
        break;
      default:
        buffer.writeln(
            "      ${field.dartName} = ${field.type.name}.fromXml(getProp(xml, '${field.name}'));");
    }
  }
  buffer.writeln('  }');
  buffer.writeln('');

  buffer.writeln('  XmlNode toXml() {');
  buffer.writeln('    final builder = XmlBuilder();');
  buffer.writeln("    builder.element('$name', nest: () {");
  for (var field in fields) {
    switch (field.type.name) {
      case 'String':
        buffer.writeln(
            "      builder.element('${field.name}', nest: ${field.dartName});");
        break;
      case 'int':
        buffer.writeln(
            "      builder.element('${field.name}', nest: ${field.dartName}.toString());");
        break;
      case 'bool':
        buffer.writeln(
            "      builder.element('${field.name}', nest: ${field.dartName} ? 'TRUE' : 'FALSE');");

        break;
      case 'DateTime':
        buffer.writeln(
            "      builder.element('${field.name}', nest: ${field.dartName}.toIso8601String());");
        break;
      default:
        buffer.writeln(
            "      builder.element('${field.name}', nest: ${field.dartName}.toXml());");
    }
  }
  buffer.writeln('    });');
  buffer.writeln('    return builder.buildDocument();');
  buffer.writeln('  }');
  buffer.writeln('');

  for (var field in fields) {
    buffer.writeln('  /// ${field.description}');
    buffer.writeln('  ${field.type.name} ${field.dartName};');
    buffer.writeln('');
  }
  buffer.writeln('}');

  return buffer.toString();
}

class FieldSpec {
  String? name;
  String? dartName;
  String? source;
  String? description;
  bool? isRequired;
  late TypeSpec type;

  @override
  String toString() {
    return '<Field $name>';
  }
}

class TypeSpec {
  String? name;
  String? dartName;
  bool isObject = false;
  bool isArray = false;

  @override
  String toString() {
    return '<TypeSpec $name>';
  }
}

String toCamelCase(String name) {
  return name.substring(0, 1).toLowerCase() + name.substring(1);
}

FieldSpec parseField(String name, Element dd) {
  final source = dd.text;
  final description =
      dd.querySelector('p')!.text.replaceAll(RegExp(r'\s+'), ' ');
  final isRequired = dd.text.contains('Required: Yes');
  final type = parseType(source);

  return FieldSpec()
    ..name = name
    ..dartName = toCamelCase(name)
    ..source = source
    ..description = description
    ..isRequired = isRequired
    ..type = type;
}

TypeSpec parseType(String source) {
  if (source.contains('Type: Base64-encoded binary data object')) {
    return TypeSpec()..name = 'String';
  }

  const typeMap = {
    'Integer': 'int',
    'Long': 'int',
    'String': 'String',
    'strings': 'String',
    'Timestamp': 'DateTime',
    'Boolean': 'bool',
  };
  final pattern = RegExp(r'Type: (Array of |)(\w+)( data type|)');
  final match = pattern.firstMatch(source)!;

  final isArray = match.group(1)!.trim().isNotEmpty;
  final isObject = match.group(3)!.trim().isNotEmpty;
  final type = match.group(2);

  final dartType = isObject ? type : typeMap[type!];
  final dartName = isArray ? 'List<$dartType>' : dartType;

  return TypeSpec()
    ..name = dartType
    ..dartName = dartName
    ..isObject = isObject
    ..isArray = isArray;
}
