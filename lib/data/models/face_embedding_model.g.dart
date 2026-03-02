// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build --delete-conflicting-outputs

part of 'face_embedding_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FaceEmbeddingModelAdapter extends TypeAdapter<FaceEmbeddingModel> {
  @override
  final int typeId = 0;

  @override
  FaceEmbeddingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FaceEmbeddingModel(
      id: fields[0] as String,
      username: fields[1] as String,
      embedding: (fields[2] as List).cast<double>(),
      registeredAtMs: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, FaceEmbeddingModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.embedding)
      ..writeByte(3)
      ..write(obj.registeredAtMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaceEmbeddingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
