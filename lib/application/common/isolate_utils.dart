// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:typed_data';

class IsolateData {
  IsolateData({
    required this.width,
    required this.height,
    required this.image,
    required this.interpreterAddress,
  });
  final int width;
  final int height;
  final Uint8List image;
  final int interpreterAddress;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': width,
      'height': height,
      'image': image.toList(),
      'interpreterAddress': interpreterAddress,
    };
  }

  factory IsolateData.fromMap(Map<String, dynamic> map) {
    return IsolateData(
      width: map['width'] as int,
      height: map['height'] as int,
      image: Uint8List.fromList(List<int>.from(map['image'] as List<dynamic>)),
      interpreterAddress: map['interpreterAddress'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory IsolateData.fromJson(String source) => IsolateData.fromMap(json.decode(source) as Map<String, dynamic>);
}
