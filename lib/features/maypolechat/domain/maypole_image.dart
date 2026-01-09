import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an image uploaded to a maypole chat room
class MaypoleImage {
  final String id;
  final String maypoleId;
  final String uploaderId;
  final String uploaderName;
  final DateTime uploadedAt;
  final String storageUrl;

  const MaypoleImage({
    required this.id,
    required this.maypoleId,
    required this.uploaderId,
    required this.uploaderName,
    required this.uploadedAt,
    required this.storageUrl,
  });

  factory MaypoleImage.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return MaypoleImage(
      id: documentId ?? map['id'] ?? '',
      maypoleId: map['maypoleId'] ?? '',
      uploaderId: map['uploaderId'] ?? '',
      uploaderName: map['uploaderName'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      storageUrl: map['storageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'maypoleId': maypoleId,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'storageUrl': storageUrl,
    };
  }

  MaypoleImage copyWith({
    String? id,
    String? maypoleId,
    String? uploaderId,
    String? uploaderName,
    DateTime? uploadedAt,
    String? storageUrl,
  }) {
    return MaypoleImage(
      id: id ?? this.id,
      maypoleId: maypoleId ?? this.maypoleId,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      storageUrl: storageUrl ?? this.storageUrl,
    );
  }
}
