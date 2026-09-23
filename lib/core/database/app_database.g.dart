// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DiariesTable extends Diaries with TableInfo<$DiariesTable, DiaryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryDateMeta = const VerificationMeta(
    'entryDate',
  );
  @override
  late final GeneratedColumn<String> entryDate = GeneratedColumn<String>(
    'entry_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryTimeMinutesMeta = const VerificationMeta(
    'entryTimeMinutes',
  );
  @override
  late final GeneratedColumn<int> entryTimeMinutes = GeneratedColumn<int>(
    'entry_time_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _utcOffsetMinutesMeta = const VerificationMeta(
    'utcOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> utcOffsetMinutes = GeneratedColumn<int>(
    'utc_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headlineMeta = const VerificationMeta(
    'headline',
  );
  @override
  late final GeneratedColumn<String> headline = GeneratedColumn<String>(
    'headline',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _companionsJsonMeta = const VerificationMeta(
    'companionsJson',
  );
  @override
  late final GeneratedColumn<String> companionsJson = GeneratedColumn<String>(
    'companions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtEpochMeta = const VerificationMeta(
    'createdAtEpoch',
  );
  @override
  late final GeneratedColumn<int> createdAtEpoch = GeneratedColumn<int>(
    'created_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtEpochMeta = const VerificationMeta(
    'updatedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> updatedAtEpoch = GeneratedColumn<int>(
    'updated_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtEpochMeta = const VerificationMeta(
    'deletedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> deletedAtEpoch = GeneratedColumn<int>(
    'deleted_at_epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purgeAtEpochMeta = const VerificationMeta(
    'purgeAtEpoch',
  );
  @override
  late final GeneratedColumn<int> purgeAtEpoch = GeneratedColumn<int>(
    'purge_at_epoch',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entryDate,
    entryTimeMinutes,
    utcOffsetMinutes,
    headline,
    body,
    mood,
    tagsJson,
    companionsJson,
    createdAtEpoch,
    updatedAtEpoch,
    deletedAtEpoch,
    purgeAtEpoch,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'diaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiaryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entry_date')) {
      context.handle(
        _entryDateMeta,
        entryDate.isAcceptableOrUnknown(data['entry_date']!, _entryDateMeta),
      );
    } else if (isInserting) {
      context.missing(_entryDateMeta);
    }
    if (data.containsKey('entry_time_minutes')) {
      context.handle(
        _entryTimeMinutesMeta,
        entryTimeMinutes.isAcceptableOrUnknown(
          data['entry_time_minutes']!,
          _entryTimeMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entryTimeMinutesMeta);
    }
    if (data.containsKey('utc_offset_minutes')) {
      context.handle(
        _utcOffsetMinutesMeta,
        utcOffsetMinutes.isAcceptableOrUnknown(
          data['utc_offset_minutes']!,
          _utcOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_utcOffsetMinutesMeta);
    }
    if (data.containsKey('headline')) {
      context.handle(
        _headlineMeta,
        headline.isAcceptableOrUnknown(data['headline']!, _headlineMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('companions_json')) {
      context.handle(
        _companionsJsonMeta,
        companionsJson.isAcceptableOrUnknown(
          data['companions_json']!,
          _companionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at_epoch')) {
      context.handle(
        _createdAtEpochMeta,
        createdAtEpoch.isAcceptableOrUnknown(
          data['created_at_epoch']!,
          _createdAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtEpochMeta);
    }
    if (data.containsKey('updated_at_epoch')) {
      context.handle(
        _updatedAtEpochMeta,
        updatedAtEpoch.isAcceptableOrUnknown(
          data['updated_at_epoch']!,
          _updatedAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtEpochMeta);
    }
    if (data.containsKey('deleted_at_epoch')) {
      context.handle(
        _deletedAtEpochMeta,
        deletedAtEpoch.isAcceptableOrUnknown(
          data['deleted_at_epoch']!,
          _deletedAtEpochMeta,
        ),
      );
    }
    if (data.containsKey('purge_at_epoch')) {
      context.handle(
        _purgeAtEpochMeta,
        purgeAtEpoch.isAcceptableOrUnknown(
          data['purge_at_epoch']!,
          _purgeAtEpochMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DiaryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiaryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_date'],
      )!,
      entryTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_time_minutes'],
      )!,
      utcOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}utc_offset_minutes'],
      )!,
      headline: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headline'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      companionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}companions_json'],
      )!,
      createdAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_epoch'],
      )!,
      updatedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_epoch'],
      )!,
      deletedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_epoch'],
      ),
      purgeAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_at_epoch'],
      ),
    );
  }

  @override
  $DiariesTable createAlias(String alias) {
    return $DiariesTable(attachedDatabase, alias);
  }
}

class DiaryRow extends DataClass implements Insertable<DiaryRow> {
  final String id;
  final String entryDate;
  final int entryTimeMinutes;
  final int utcOffsetMinutes;
  final String? headline;
  final String? body;
  final String? mood;
  final String tagsJson;
  final String companionsJson;
  final int createdAtEpoch;
  final int updatedAtEpoch;
  final int? deletedAtEpoch;
  final int? purgeAtEpoch;
  const DiaryRow({
    required this.id,
    required this.entryDate,
    required this.entryTimeMinutes,
    required this.utcOffsetMinutes,
    this.headline,
    this.body,
    this.mood,
    required this.tagsJson,
    required this.companionsJson,
    required this.createdAtEpoch,
    required this.updatedAtEpoch,
    this.deletedAtEpoch,
    this.purgeAtEpoch,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entry_date'] = Variable<String>(entryDate);
    map['entry_time_minutes'] = Variable<int>(entryTimeMinutes);
    map['utc_offset_minutes'] = Variable<int>(utcOffsetMinutes);
    if (!nullToAbsent || headline != null) {
      map['headline'] = Variable<String>(headline);
    }
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    map['companions_json'] = Variable<String>(companionsJson);
    map['created_at_epoch'] = Variable<int>(createdAtEpoch);
    map['updated_at_epoch'] = Variable<int>(updatedAtEpoch);
    if (!nullToAbsent || deletedAtEpoch != null) {
      map['deleted_at_epoch'] = Variable<int>(deletedAtEpoch);
    }
    if (!nullToAbsent || purgeAtEpoch != null) {
      map['purge_at_epoch'] = Variable<int>(purgeAtEpoch);
    }
    return map;
  }

  DiariesCompanion toCompanion(bool nullToAbsent) {
    return DiariesCompanion(
      id: Value(id),
      entryDate: Value(entryDate),
      entryTimeMinutes: Value(entryTimeMinutes),
      utcOffsetMinutes: Value(utcOffsetMinutes),
      headline: headline == null && nullToAbsent
          ? const Value.absent()
          : Value(headline),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      tagsJson: Value(tagsJson),
      companionsJson: Value(companionsJson),
      createdAtEpoch: Value(createdAtEpoch),
      updatedAtEpoch: Value(updatedAtEpoch),
      deletedAtEpoch: deletedAtEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtEpoch),
      purgeAtEpoch: purgeAtEpoch == null && nullToAbsent
          ? const Value.absent()
          : Value(purgeAtEpoch),
    );
  }

  factory DiaryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiaryRow(
      id: serializer.fromJson<String>(json['id']),
      entryDate: serializer.fromJson<String>(json['entryDate']),
      entryTimeMinutes: serializer.fromJson<int>(json['entryTimeMinutes']),
      utcOffsetMinutes: serializer.fromJson<int>(json['utcOffsetMinutes']),
      headline: serializer.fromJson<String?>(json['headline']),
      body: serializer.fromJson<String?>(json['body']),
      mood: serializer.fromJson<String?>(json['mood']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      companionsJson: serializer.fromJson<String>(json['companionsJson']),
      createdAtEpoch: serializer.fromJson<int>(json['createdAtEpoch']),
      updatedAtEpoch: serializer.fromJson<int>(json['updatedAtEpoch']),
      deletedAtEpoch: serializer.fromJson<int?>(json['deletedAtEpoch']),
      purgeAtEpoch: serializer.fromJson<int?>(json['purgeAtEpoch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entryDate': serializer.toJson<String>(entryDate),
      'entryTimeMinutes': serializer.toJson<int>(entryTimeMinutes),
      'utcOffsetMinutes': serializer.toJson<int>(utcOffsetMinutes),
      'headline': serializer.toJson<String?>(headline),
      'body': serializer.toJson<String?>(body),
      'mood': serializer.toJson<String?>(mood),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'companionsJson': serializer.toJson<String>(companionsJson),
      'createdAtEpoch': serializer.toJson<int>(createdAtEpoch),
      'updatedAtEpoch': serializer.toJson<int>(updatedAtEpoch),
      'deletedAtEpoch': serializer.toJson<int?>(deletedAtEpoch),
      'purgeAtEpoch': serializer.toJson<int?>(purgeAtEpoch),
    };
  }

  DiaryRow copyWith({
    String? id,
    String? entryDate,
    int? entryTimeMinutes,
    int? utcOffsetMinutes,
    Value<String?> headline = const Value.absent(),
    Value<String?> body = const Value.absent(),
    Value<String?> mood = const Value.absent(),
    String? tagsJson,
    String? companionsJson,
    int? createdAtEpoch,
    int? updatedAtEpoch,
    Value<int?> deletedAtEpoch = const Value.absent(),
    Value<int?> purgeAtEpoch = const Value.absent(),
  }) => DiaryRow(
    id: id ?? this.id,
    entryDate: entryDate ?? this.entryDate,
    entryTimeMinutes: entryTimeMinutes ?? this.entryTimeMinutes,
    utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
    headline: headline.present ? headline.value : this.headline,
    body: body.present ? body.value : this.body,
    mood: mood.present ? mood.value : this.mood,
    tagsJson: tagsJson ?? this.tagsJson,
    companionsJson: companionsJson ?? this.companionsJson,
    createdAtEpoch: createdAtEpoch ?? this.createdAtEpoch,
    updatedAtEpoch: updatedAtEpoch ?? this.updatedAtEpoch,
    deletedAtEpoch: deletedAtEpoch.present
        ? deletedAtEpoch.value
        : this.deletedAtEpoch,
    purgeAtEpoch: purgeAtEpoch.present ? purgeAtEpoch.value : this.purgeAtEpoch,
  );
  DiaryRow copyWithCompanion(DiariesCompanion data) {
    return DiaryRow(
      id: data.id.present ? data.id.value : this.id,
      entryDate: data.entryDate.present ? data.entryDate.value : this.entryDate,
      entryTimeMinutes: data.entryTimeMinutes.present
          ? data.entryTimeMinutes.value
          : this.entryTimeMinutes,
      utcOffsetMinutes: data.utcOffsetMinutes.present
          ? data.utcOffsetMinutes.value
          : this.utcOffsetMinutes,
      headline: data.headline.present ? data.headline.value : this.headline,
      body: data.body.present ? data.body.value : this.body,
      mood: data.mood.present ? data.mood.value : this.mood,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      companionsJson: data.companionsJson.present
          ? data.companionsJson.value
          : this.companionsJson,
      createdAtEpoch: data.createdAtEpoch.present
          ? data.createdAtEpoch.value
          : this.createdAtEpoch,
      updatedAtEpoch: data.updatedAtEpoch.present
          ? data.updatedAtEpoch.value
          : this.updatedAtEpoch,
      deletedAtEpoch: data.deletedAtEpoch.present
          ? data.deletedAtEpoch.value
          : this.deletedAtEpoch,
      purgeAtEpoch: data.purgeAtEpoch.present
          ? data.purgeAtEpoch.value
          : this.purgeAtEpoch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiaryRow(')
          ..write('id: $id, ')
          ..write('entryDate: $entryDate, ')
          ..write('entryTimeMinutes: $entryTimeMinutes, ')
          ..write('utcOffsetMinutes: $utcOffsetMinutes, ')
          ..write('headline: $headline, ')
          ..write('body: $body, ')
          ..write('mood: $mood, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('companionsJson: $companionsJson, ')
          ..write('createdAtEpoch: $createdAtEpoch, ')
          ..write('updatedAtEpoch: $updatedAtEpoch, ')
          ..write('deletedAtEpoch: $deletedAtEpoch, ')
          ..write('purgeAtEpoch: $purgeAtEpoch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entryDate,
    entryTimeMinutes,
    utcOffsetMinutes,
    headline,
    body,
    mood,
    tagsJson,
    companionsJson,
    createdAtEpoch,
    updatedAtEpoch,
    deletedAtEpoch,
    purgeAtEpoch,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiaryRow &&
          other.id == this.id &&
          other.entryDate == this.entryDate &&
          other.entryTimeMinutes == this.entryTimeMinutes &&
          other.utcOffsetMinutes == this.utcOffsetMinutes &&
          other.headline == this.headline &&
          other.body == this.body &&
          other.mood == this.mood &&
          other.tagsJson == this.tagsJson &&
          other.companionsJson == this.companionsJson &&
          other.createdAtEpoch == this.createdAtEpoch &&
          other.updatedAtEpoch == this.updatedAtEpoch &&
          other.deletedAtEpoch == this.deletedAtEpoch &&
          other.purgeAtEpoch == this.purgeAtEpoch);
}

class DiariesCompanion extends UpdateCompanion<DiaryRow> {
  final Value<String> id;
  final Value<String> entryDate;
  final Value<int> entryTimeMinutes;
  final Value<int> utcOffsetMinutes;
  final Value<String?> headline;
  final Value<String?> body;
  final Value<String?> mood;
  final Value<String> tagsJson;
  final Value<String> companionsJson;
  final Value<int> createdAtEpoch;
  final Value<int> updatedAtEpoch;
  final Value<int?> deletedAtEpoch;
  final Value<int?> purgeAtEpoch;
  final Value<int> rowid;
  const DiariesCompanion({
    this.id = const Value.absent(),
    this.entryDate = const Value.absent(),
    this.entryTimeMinutes = const Value.absent(),
    this.utcOffsetMinutes = const Value.absent(),
    this.headline = const Value.absent(),
    this.body = const Value.absent(),
    this.mood = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.companionsJson = const Value.absent(),
    this.createdAtEpoch = const Value.absent(),
    this.updatedAtEpoch = const Value.absent(),
    this.deletedAtEpoch = const Value.absent(),
    this.purgeAtEpoch = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiariesCompanion.insert({
    required String id,
    required String entryDate,
    required int entryTimeMinutes,
    required int utcOffsetMinutes,
    this.headline = const Value.absent(),
    this.body = const Value.absent(),
    this.mood = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.companionsJson = const Value.absent(),
    required int createdAtEpoch,
    required int updatedAtEpoch,
    this.deletedAtEpoch = const Value.absent(),
    this.purgeAtEpoch = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entryDate = Value(entryDate),
       entryTimeMinutes = Value(entryTimeMinutes),
       utcOffsetMinutes = Value(utcOffsetMinutes),
       createdAtEpoch = Value(createdAtEpoch),
       updatedAtEpoch = Value(updatedAtEpoch);
  static Insertable<DiaryRow> custom({
    Expression<String>? id,
    Expression<String>? entryDate,
    Expression<int>? entryTimeMinutes,
    Expression<int>? utcOffsetMinutes,
    Expression<String>? headline,
    Expression<String>? body,
    Expression<String>? mood,
    Expression<String>? tagsJson,
    Expression<String>? companionsJson,
    Expression<int>? createdAtEpoch,
    Expression<int>? updatedAtEpoch,
    Expression<int>? deletedAtEpoch,
    Expression<int>? purgeAtEpoch,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entryDate != null) 'entry_date': entryDate,
      if (entryTimeMinutes != null) 'entry_time_minutes': entryTimeMinutes,
      if (utcOffsetMinutes != null) 'utc_offset_minutes': utcOffsetMinutes,
      if (headline != null) 'headline': headline,
      if (body != null) 'body': body,
      if (mood != null) 'mood': mood,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (companionsJson != null) 'companions_json': companionsJson,
      if (createdAtEpoch != null) 'created_at_epoch': createdAtEpoch,
      if (updatedAtEpoch != null) 'updated_at_epoch': updatedAtEpoch,
      if (deletedAtEpoch != null) 'deleted_at_epoch': deletedAtEpoch,
      if (purgeAtEpoch != null) 'purge_at_epoch': purgeAtEpoch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiariesCompanion copyWith({
    Value<String>? id,
    Value<String>? entryDate,
    Value<int>? entryTimeMinutes,
    Value<int>? utcOffsetMinutes,
    Value<String?>? headline,
    Value<String?>? body,
    Value<String?>? mood,
    Value<String>? tagsJson,
    Value<String>? companionsJson,
    Value<int>? createdAtEpoch,
    Value<int>? updatedAtEpoch,
    Value<int?>? deletedAtEpoch,
    Value<int?>? purgeAtEpoch,
    Value<int>? rowid,
  }) {
    return DiariesCompanion(
      id: id ?? this.id,
      entryDate: entryDate ?? this.entryDate,
      entryTimeMinutes: entryTimeMinutes ?? this.entryTimeMinutes,
      utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
      headline: headline ?? this.headline,
      body: body ?? this.body,
      mood: mood ?? this.mood,
      tagsJson: tagsJson ?? this.tagsJson,
      companionsJson: companionsJson ?? this.companionsJson,
      createdAtEpoch: createdAtEpoch ?? this.createdAtEpoch,
      updatedAtEpoch: updatedAtEpoch ?? this.updatedAtEpoch,
      deletedAtEpoch: deletedAtEpoch ?? this.deletedAtEpoch,
      purgeAtEpoch: purgeAtEpoch ?? this.purgeAtEpoch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entryDate.present) {
      map['entry_date'] = Variable<String>(entryDate.value);
    }
    if (entryTimeMinutes.present) {
      map['entry_time_minutes'] = Variable<int>(entryTimeMinutes.value);
    }
    if (utcOffsetMinutes.present) {
      map['utc_offset_minutes'] = Variable<int>(utcOffsetMinutes.value);
    }
    if (headline.present) {
      map['headline'] = Variable<String>(headline.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (companionsJson.present) {
      map['companions_json'] = Variable<String>(companionsJson.value);
    }
    if (createdAtEpoch.present) {
      map['created_at_epoch'] = Variable<int>(createdAtEpoch.value);
    }
    if (updatedAtEpoch.present) {
      map['updated_at_epoch'] = Variable<int>(updatedAtEpoch.value);
    }
    if (deletedAtEpoch.present) {
      map['deleted_at_epoch'] = Variable<int>(deletedAtEpoch.value);
    }
    if (purgeAtEpoch.present) {
      map['purge_at_epoch'] = Variable<int>(purgeAtEpoch.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DiariesCompanion(')
          ..write('id: $id, ')
          ..write('entryDate: $entryDate, ')
          ..write('entryTimeMinutes: $entryTimeMinutes, ')
          ..write('utcOffsetMinutes: $utcOffsetMinutes, ')
          ..write('headline: $headline, ')
          ..write('body: $body, ')
          ..write('mood: $mood, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('companionsJson: $companionsJson, ')
          ..write('createdAtEpoch: $createdAtEpoch, ')
          ..write('updatedAtEpoch: $updatedAtEpoch, ')
          ..write('deletedAtEpoch: $deletedAtEpoch, ')
          ..write('purgeAtEpoch: $purgeAtEpoch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaEntriesTable extends MediaEntries
    with TableInfo<$MediaEntriesTable, MediaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diaryIdMeta = const VerificationMeta(
    'diaryId',
  );
  @override
  late final GeneratedColumn<String> diaryId = GeneratedColumn<String>(
    'diary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES diaries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedPathMeta = const VerificationMeta(
    'encryptedPath',
  );
  @override
  late final GeneratedColumn<String> encryptedPath = GeneratedColumn<String>(
    'encrypted_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _renderedPathMeta = const VerificationMeta(
    'renderedPath',
  );
  @override
  late final GeneratedColumn<String> renderedPath = GeneratedColumn<String>(
    'rendered_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaKeyBase64Meta = const VerificationMeta(
    'mediaKeyBase64',
  );
  @override
  late final GeneratedColumn<String> mediaKeyBase64 = GeneratedColumn<String>(
    'media_key_base64',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteLengthMeta = const VerificationMeta(
    'byteLength',
  );
  @override
  late final GeneratedColumn<int> byteLength = GeneratedColumn<int>(
    'byte_length',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMillisMeta = const VerificationMeta(
    'durationMillis',
  );
  @override
  late final GeneratedColumn<int> durationMillis = GeneratedColumn<int>(
    'duration_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _representativeMillisMeta =
      const VerificationMeta('representativeMillis');
  @override
  late final GeneratedColumn<int> representativeMillis = GeneratedColumn<int>(
    'representative_millis',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editHistoryJsonMeta = const VerificationMeta(
    'editHistoryJson',
  );
  @override
  late final GeneratedColumn<String> editHistoryJson = GeneratedColumn<String>(
    'edit_history_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editVersionMeta = const VerificationMeta(
    'editVersion',
  );
  @override
  late final GeneratedColumn<int> editVersion = GeneratedColumn<int>(
    'edit_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    diaryId,
    sortOrder,
    kind,
    mimeType,
    encryptedPath,
    thumbnailPath,
    renderedPath,
    mediaKeyBase64,
    byteLength,
    width,
    height,
    durationMillis,
    representativeMillis,
    editHistoryJson,
    editVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('diary_id')) {
      context.handle(
        _diaryIdMeta,
        diaryId.isAcceptableOrUnknown(data['diary_id']!, _diaryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_diaryIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('encrypted_path')) {
      context.handle(
        _encryptedPathMeta,
        encryptedPath.isAcceptableOrUnknown(
          data['encrypted_path']!,
          _encryptedPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedPathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('rendered_path')) {
      context.handle(
        _renderedPathMeta,
        renderedPath.isAcceptableOrUnknown(
          data['rendered_path']!,
          _renderedPathMeta,
        ),
      );
    }
    if (data.containsKey('media_key_base64')) {
      context.handle(
        _mediaKeyBase64Meta,
        mediaKeyBase64.isAcceptableOrUnknown(
          data['media_key_base64']!,
          _mediaKeyBase64Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaKeyBase64Meta);
    }
    if (data.containsKey('byte_length')) {
      context.handle(
        _byteLengthMeta,
        byteLength.isAcceptableOrUnknown(data['byte_length']!, _byteLengthMeta),
      );
    } else if (isInserting) {
      context.missing(_byteLengthMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('duration_millis')) {
      context.handle(
        _durationMillisMeta,
        durationMillis.isAcceptableOrUnknown(
          data['duration_millis']!,
          _durationMillisMeta,
        ),
      );
    }
    if (data.containsKey('representative_millis')) {
      context.handle(
        _representativeMillisMeta,
        representativeMillis.isAcceptableOrUnknown(
          data['representative_millis']!,
          _representativeMillisMeta,
        ),
      );
    }
    if (data.containsKey('edit_history_json')) {
      context.handle(
        _editHistoryJsonMeta,
        editHistoryJson.isAcceptableOrUnknown(
          data['edit_history_json']!,
          _editHistoryJsonMeta,
        ),
      );
    }
    if (data.containsKey('edit_version')) {
      context.handle(
        _editVersionMeta,
        editVersion.isAcceptableOrUnknown(
          data['edit_version']!,
          _editVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      diaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diary_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      encryptedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_path'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      renderedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rendered_path'],
      ),
      mediaKeyBase64: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_key_base64'],
      )!,
      byteLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_length'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      durationMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_millis'],
      ),
      representativeMillis: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}representative_millis'],
      ),
      editHistoryJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edit_history_json'],
      ),
      editVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edit_version'],
      )!,
    );
  }

  @override
  $MediaEntriesTable createAlias(String alias) {
    return $MediaEntriesTable(attachedDatabase, alias);
  }
}

class MediaRow extends DataClass implements Insertable<MediaRow> {
  final String id;
  final String diaryId;
  final int sortOrder;
  final String kind;
  final String mimeType;
  final String encryptedPath;
  final String? thumbnailPath;
  final String? renderedPath;
  final String mediaKeyBase64;
  final int byteLength;
  final int? width;
  final int? height;
  final int? durationMillis;
  final int? representativeMillis;
  final String? editHistoryJson;
  final int editVersion;
  const MediaRow({
    required this.id,
    required this.diaryId,
    required this.sortOrder,
    required this.kind,
    required this.mimeType,
    required this.encryptedPath,
    this.thumbnailPath,
    this.renderedPath,
    required this.mediaKeyBase64,
    required this.byteLength,
    this.width,
    this.height,
    this.durationMillis,
    this.representativeMillis,
    this.editHistoryJson,
    required this.editVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['diary_id'] = Variable<String>(diaryId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['kind'] = Variable<String>(kind);
    map['mime_type'] = Variable<String>(mimeType);
    map['encrypted_path'] = Variable<String>(encryptedPath);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || renderedPath != null) {
      map['rendered_path'] = Variable<String>(renderedPath);
    }
    map['media_key_base64'] = Variable<String>(mediaKeyBase64);
    map['byte_length'] = Variable<int>(byteLength);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || durationMillis != null) {
      map['duration_millis'] = Variable<int>(durationMillis);
    }
    if (!nullToAbsent || representativeMillis != null) {
      map['representative_millis'] = Variable<int>(representativeMillis);
    }
    if (!nullToAbsent || editHistoryJson != null) {
      map['edit_history_json'] = Variable<String>(editHistoryJson);
    }
    map['edit_version'] = Variable<int>(editVersion);
    return map;
  }

  MediaEntriesCompanion toCompanion(bool nullToAbsent) {
    return MediaEntriesCompanion(
      id: Value(id),
      diaryId: Value(diaryId),
      sortOrder: Value(sortOrder),
      kind: Value(kind),
      mimeType: Value(mimeType),
      encryptedPath: Value(encryptedPath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      renderedPath: renderedPath == null && nullToAbsent
          ? const Value.absent()
          : Value(renderedPath),
      mediaKeyBase64: Value(mediaKeyBase64),
      byteLength: Value(byteLength),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      durationMillis: durationMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMillis),
      representativeMillis: representativeMillis == null && nullToAbsent
          ? const Value.absent()
          : Value(representativeMillis),
      editHistoryJson: editHistoryJson == null && nullToAbsent
          ? const Value.absent()
          : Value(editHistoryJson),
      editVersion: Value(editVersion),
    );
  }

  factory MediaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaRow(
      id: serializer.fromJson<String>(json['id']),
      diaryId: serializer.fromJson<String>(json['diaryId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      kind: serializer.fromJson<String>(json['kind']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      encryptedPath: serializer.fromJson<String>(json['encryptedPath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      renderedPath: serializer.fromJson<String?>(json['renderedPath']),
      mediaKeyBase64: serializer.fromJson<String>(json['mediaKeyBase64']),
      byteLength: serializer.fromJson<int>(json['byteLength']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      durationMillis: serializer.fromJson<int?>(json['durationMillis']),
      representativeMillis: serializer.fromJson<int?>(
        json['representativeMillis'],
      ),
      editHistoryJson: serializer.fromJson<String?>(json['editHistoryJson']),
      editVersion: serializer.fromJson<int>(json['editVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'diaryId': serializer.toJson<String>(diaryId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'kind': serializer.toJson<String>(kind),
      'mimeType': serializer.toJson<String>(mimeType),
      'encryptedPath': serializer.toJson<String>(encryptedPath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'renderedPath': serializer.toJson<String?>(renderedPath),
      'mediaKeyBase64': serializer.toJson<String>(mediaKeyBase64),
      'byteLength': serializer.toJson<int>(byteLength),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'durationMillis': serializer.toJson<int?>(durationMillis),
      'representativeMillis': serializer.toJson<int?>(representativeMillis),
      'editHistoryJson': serializer.toJson<String?>(editHistoryJson),
      'editVersion': serializer.toJson<int>(editVersion),
    };
  }

  MediaRow copyWith({
    String? id,
    String? diaryId,
    int? sortOrder,
    String? kind,
    String? mimeType,
    String? encryptedPath,
    Value<String?> thumbnailPath = const Value.absent(),
    Value<String?> renderedPath = const Value.absent(),
    String? mediaKeyBase64,
    int? byteLength,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<int?> durationMillis = const Value.absent(),
    Value<int?> representativeMillis = const Value.absent(),
    Value<String?> editHistoryJson = const Value.absent(),
    int? editVersion,
  }) => MediaRow(
    id: id ?? this.id,
    diaryId: diaryId ?? this.diaryId,
    sortOrder: sortOrder ?? this.sortOrder,
    kind: kind ?? this.kind,
    mimeType: mimeType ?? this.mimeType,
    encryptedPath: encryptedPath ?? this.encryptedPath,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    renderedPath: renderedPath.present ? renderedPath.value : this.renderedPath,
    mediaKeyBase64: mediaKeyBase64 ?? this.mediaKeyBase64,
    byteLength: byteLength ?? this.byteLength,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    durationMillis: durationMillis.present
        ? durationMillis.value
        : this.durationMillis,
    representativeMillis: representativeMillis.present
        ? representativeMillis.value
        : this.representativeMillis,
    editHistoryJson: editHistoryJson.present
        ? editHistoryJson.value
        : this.editHistoryJson,
    editVersion: editVersion ?? this.editVersion,
  );
  MediaRow copyWithCompanion(MediaEntriesCompanion data) {
    return MediaRow(
      id: data.id.present ? data.id.value : this.id,
      diaryId: data.diaryId.present ? data.diaryId.value : this.diaryId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      kind: data.kind.present ? data.kind.value : this.kind,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      encryptedPath: data.encryptedPath.present
          ? data.encryptedPath.value
          : this.encryptedPath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      renderedPath: data.renderedPath.present
          ? data.renderedPath.value
          : this.renderedPath,
      mediaKeyBase64: data.mediaKeyBase64.present
          ? data.mediaKeyBase64.value
          : this.mediaKeyBase64,
      byteLength: data.byteLength.present
          ? data.byteLength.value
          : this.byteLength,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      durationMillis: data.durationMillis.present
          ? data.durationMillis.value
          : this.durationMillis,
      representativeMillis: data.representativeMillis.present
          ? data.representativeMillis.value
          : this.representativeMillis,
      editHistoryJson: data.editHistoryJson.present
          ? data.editHistoryJson.value
          : this.editHistoryJson,
      editVersion: data.editVersion.present
          ? data.editVersion.value
          : this.editVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaRow(')
          ..write('id: $id, ')
          ..write('diaryId: $diaryId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('kind: $kind, ')
          ..write('mimeType: $mimeType, ')
          ..write('encryptedPath: $encryptedPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('renderedPath: $renderedPath, ')
          ..write('mediaKeyBase64: $mediaKeyBase64, ')
          ..write('byteLength: $byteLength, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationMillis: $durationMillis, ')
          ..write('representativeMillis: $representativeMillis, ')
          ..write('editHistoryJson: $editHistoryJson, ')
          ..write('editVersion: $editVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    diaryId,
    sortOrder,
    kind,
    mimeType,
    encryptedPath,
    thumbnailPath,
    renderedPath,
    mediaKeyBase64,
    byteLength,
    width,
    height,
    durationMillis,
    representativeMillis,
    editHistoryJson,
    editVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaRow &&
          other.id == this.id &&
          other.diaryId == this.diaryId &&
          other.sortOrder == this.sortOrder &&
          other.kind == this.kind &&
          other.mimeType == this.mimeType &&
          other.encryptedPath == this.encryptedPath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.renderedPath == this.renderedPath &&
          other.mediaKeyBase64 == this.mediaKeyBase64 &&
          other.byteLength == this.byteLength &&
          other.width == this.width &&
          other.height == this.height &&
          other.durationMillis == this.durationMillis &&
          other.representativeMillis == this.representativeMillis &&
          other.editHistoryJson == this.editHistoryJson &&
          other.editVersion == this.editVersion);
}

class MediaEntriesCompanion extends UpdateCompanion<MediaRow> {
  final Value<String> id;
  final Value<String> diaryId;
  final Value<int> sortOrder;
  final Value<String> kind;
  final Value<String> mimeType;
  final Value<String> encryptedPath;
  final Value<String?> thumbnailPath;
  final Value<String?> renderedPath;
  final Value<String> mediaKeyBase64;
  final Value<int> byteLength;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> durationMillis;
  final Value<int?> representativeMillis;
  final Value<String?> editHistoryJson;
  final Value<int> editVersion;
  final Value<int> rowid;
  const MediaEntriesCompanion({
    this.id = const Value.absent(),
    this.diaryId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.kind = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.encryptedPath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.renderedPath = const Value.absent(),
    this.mediaKeyBase64 = const Value.absent(),
    this.byteLength = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationMillis = const Value.absent(),
    this.representativeMillis = const Value.absent(),
    this.editHistoryJson = const Value.absent(),
    this.editVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaEntriesCompanion.insert({
    required String id,
    required String diaryId,
    required int sortOrder,
    required String kind,
    required String mimeType,
    required String encryptedPath,
    this.thumbnailPath = const Value.absent(),
    this.renderedPath = const Value.absent(),
    required String mediaKeyBase64,
    required int byteLength,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.durationMillis = const Value.absent(),
    this.representativeMillis = const Value.absent(),
    this.editHistoryJson = const Value.absent(),
    this.editVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       diaryId = Value(diaryId),
       sortOrder = Value(sortOrder),
       kind = Value(kind),
       mimeType = Value(mimeType),
       encryptedPath = Value(encryptedPath),
       mediaKeyBase64 = Value(mediaKeyBase64),
       byteLength = Value(byteLength);
  static Insertable<MediaRow> custom({
    Expression<String>? id,
    Expression<String>? diaryId,
    Expression<int>? sortOrder,
    Expression<String>? kind,
    Expression<String>? mimeType,
    Expression<String>? encryptedPath,
    Expression<String>? thumbnailPath,
    Expression<String>? renderedPath,
    Expression<String>? mediaKeyBase64,
    Expression<int>? byteLength,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? durationMillis,
    Expression<int>? representativeMillis,
    Expression<String>? editHistoryJson,
    Expression<int>? editVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (diaryId != null) 'diary_id': diaryId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (kind != null) 'kind': kind,
      if (mimeType != null) 'mime_type': mimeType,
      if (encryptedPath != null) 'encrypted_path': encryptedPath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (renderedPath != null) 'rendered_path': renderedPath,
      if (mediaKeyBase64 != null) 'media_key_base64': mediaKeyBase64,
      if (byteLength != null) 'byte_length': byteLength,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (durationMillis != null) 'duration_millis': durationMillis,
      if (representativeMillis != null)
        'representative_millis': representativeMillis,
      if (editHistoryJson != null) 'edit_history_json': editHistoryJson,
      if (editVersion != null) 'edit_version': editVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? diaryId,
    Value<int>? sortOrder,
    Value<String>? kind,
    Value<String>? mimeType,
    Value<String>? encryptedPath,
    Value<String?>? thumbnailPath,
    Value<String?>? renderedPath,
    Value<String>? mediaKeyBase64,
    Value<int>? byteLength,
    Value<int?>? width,
    Value<int?>? height,
    Value<int?>? durationMillis,
    Value<int?>? representativeMillis,
    Value<String?>? editHistoryJson,
    Value<int>? editVersion,
    Value<int>? rowid,
  }) {
    return MediaEntriesCompanion(
      id: id ?? this.id,
      diaryId: diaryId ?? this.diaryId,
      sortOrder: sortOrder ?? this.sortOrder,
      kind: kind ?? this.kind,
      mimeType: mimeType ?? this.mimeType,
      encryptedPath: encryptedPath ?? this.encryptedPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      renderedPath: renderedPath ?? this.renderedPath,
      mediaKeyBase64: mediaKeyBase64 ?? this.mediaKeyBase64,
      byteLength: byteLength ?? this.byteLength,
      width: width ?? this.width,
      height: height ?? this.height,
      durationMillis: durationMillis ?? this.durationMillis,
      representativeMillis: representativeMillis ?? this.representativeMillis,
      editHistoryJson: editHistoryJson ?? this.editHistoryJson,
      editVersion: editVersion ?? this.editVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (diaryId.present) {
      map['diary_id'] = Variable<String>(diaryId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (encryptedPath.present) {
      map['encrypted_path'] = Variable<String>(encryptedPath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (renderedPath.present) {
      map['rendered_path'] = Variable<String>(renderedPath.value);
    }
    if (mediaKeyBase64.present) {
      map['media_key_base64'] = Variable<String>(mediaKeyBase64.value);
    }
    if (byteLength.present) {
      map['byte_length'] = Variable<int>(byteLength.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (durationMillis.present) {
      map['duration_millis'] = Variable<int>(durationMillis.value);
    }
    if (representativeMillis.present) {
      map['representative_millis'] = Variable<int>(representativeMillis.value);
    }
    if (editHistoryJson.present) {
      map['edit_history_json'] = Variable<String>(editHistoryJson.value);
    }
    if (editVersion.present) {
      map['edit_version'] = Variable<int>(editVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaEntriesCompanion(')
          ..write('id: $id, ')
          ..write('diaryId: $diaryId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('kind: $kind, ')
          ..write('mimeType: $mimeType, ')
          ..write('encryptedPath: $encryptedPath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('renderedPath: $renderedPath, ')
          ..write('mediaKeyBase64: $mediaKeyBase64, ')
          ..write('byteLength: $byteLength, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('durationMillis: $durationMillis, ')
          ..write('representativeMillis: $representativeMillis, ')
          ..write('editHistoryJson: $editHistoryJson, ')
          ..write('editVersion: $editVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeatherEntriesTable extends WeatherEntries
    with TableInfo<$WeatherEntriesTable, WeatherRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeatherEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _diaryIdMeta = const VerificationMeta(
    'diaryId',
  );
  @override
  late final GeneratedColumn<String> diaryId = GeneratedColumn<String>(
    'diary_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES diaries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minimumTemperatureMeta =
      const VerificationMeta('minimumTemperature');
  @override
  late final GeneratedColumn<double> minimumTemperature =
      GeneratedColumn<double>(
        'minimum_temperature',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _maximumTemperatureMeta =
      const VerificationMeta('maximumTemperature');
  @override
  late final GeneratedColumn<double> maximumTemperature =
      GeneratedColumn<double>(
        'maximum_temperature',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _precipitationMeta = const VerificationMeta(
    'precipitation',
  );
  @override
  late final GeneratedColumn<bool> precipitation = GeneratedColumn<bool>(
    'precipitation',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("precipitation" IN (0, 1))',
    ),
  );
  static const VerificationMeta _displayMaskMeta = const VerificationMeta(
    'displayMask',
  );
  @override
  late final GeneratedColumn<int> displayMask = GeneratedColumn<int>(
    'display_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    diaryId,
    condition,
    temperature,
    minimumTemperature,
    maximumTemperature,
    precipitation,
    displayMask,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weather_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeatherRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('diary_id')) {
      context.handle(
        _diaryIdMeta,
        diaryId.isAcceptableOrUnknown(data['diary_id']!, _diaryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_diaryIdMeta);
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    }
    if (data.containsKey('minimum_temperature')) {
      context.handle(
        _minimumTemperatureMeta,
        minimumTemperature.isAcceptableOrUnknown(
          data['minimum_temperature']!,
          _minimumTemperatureMeta,
        ),
      );
    }
    if (data.containsKey('maximum_temperature')) {
      context.handle(
        _maximumTemperatureMeta,
        maximumTemperature.isAcceptableOrUnknown(
          data['maximum_temperature']!,
          _maximumTemperatureMeta,
        ),
      );
    }
    if (data.containsKey('precipitation')) {
      context.handle(
        _precipitationMeta,
        precipitation.isAcceptableOrUnknown(
          data['precipitation']!,
          _precipitationMeta,
        ),
      );
    }
    if (data.containsKey('display_mask')) {
      context.handle(
        _displayMaskMeta,
        displayMask.isAcceptableOrUnknown(
          data['display_mask']!,
          _displayMaskMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {diaryId};
  @override
  WeatherRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeatherRow(
      diaryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diary_id'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      ),
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      ),
      minimumTemperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}minimum_temperature'],
      ),
      maximumTemperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}maximum_temperature'],
      ),
      precipitation: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}precipitation'],
      ),
      displayMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_mask'],
      )!,
    );
  }

  @override
  $WeatherEntriesTable createAlias(String alias) {
    return $WeatherEntriesTable(attachedDatabase, alias);
  }
}

class WeatherRow extends DataClass implements Insertable<WeatherRow> {
  final String diaryId;
  final String? condition;
  final double? temperature;
  final double? minimumTemperature;
  final double? maximumTemperature;
  final bool? precipitation;
  final int displayMask;
  const WeatherRow({
    required this.diaryId,
    this.condition,
    this.temperature,
    this.minimumTemperature,
    this.maximumTemperature,
    this.precipitation,
    required this.displayMask,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['diary_id'] = Variable<String>(diaryId);
    if (!nullToAbsent || condition != null) {
      map['condition'] = Variable<String>(condition);
    }
    if (!nullToAbsent || temperature != null) {
      map['temperature'] = Variable<double>(temperature);
    }
    if (!nullToAbsent || minimumTemperature != null) {
      map['minimum_temperature'] = Variable<double>(minimumTemperature);
    }
    if (!nullToAbsent || maximumTemperature != null) {
      map['maximum_temperature'] = Variable<double>(maximumTemperature);
    }
    if (!nullToAbsent || precipitation != null) {
      map['precipitation'] = Variable<bool>(precipitation);
    }
    map['display_mask'] = Variable<int>(displayMask);
    return map;
  }

  WeatherEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeatherEntriesCompanion(
      diaryId: Value(diaryId),
      condition: condition == null && nullToAbsent
          ? const Value.absent()
          : Value(condition),
      temperature: temperature == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature),
      minimumTemperature: minimumTemperature == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumTemperature),
      maximumTemperature: maximumTemperature == null && nullToAbsent
          ? const Value.absent()
          : Value(maximumTemperature),
      precipitation: precipitation == null && nullToAbsent
          ? const Value.absent()
          : Value(precipitation),
      displayMask: Value(displayMask),
    );
  }

  factory WeatherRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherRow(
      diaryId: serializer.fromJson<String>(json['diaryId']),
      condition: serializer.fromJson<String?>(json['condition']),
      temperature: serializer.fromJson<double?>(json['temperature']),
      minimumTemperature: serializer.fromJson<double?>(
        json['minimumTemperature'],
      ),
      maximumTemperature: serializer.fromJson<double?>(
        json['maximumTemperature'],
      ),
      precipitation: serializer.fromJson<bool?>(json['precipitation']),
      displayMask: serializer.fromJson<int>(json['displayMask']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'diaryId': serializer.toJson<String>(diaryId),
      'condition': serializer.toJson<String?>(condition),
      'temperature': serializer.toJson<double?>(temperature),
      'minimumTemperature': serializer.toJson<double?>(minimumTemperature),
      'maximumTemperature': serializer.toJson<double?>(maximumTemperature),
      'precipitation': serializer.toJson<bool?>(precipitation),
      'displayMask': serializer.toJson<int>(displayMask),
    };
  }

  WeatherRow copyWith({
    String? diaryId,
    Value<String?> condition = const Value.absent(),
    Value<double?> temperature = const Value.absent(),
    Value<double?> minimumTemperature = const Value.absent(),
    Value<double?> maximumTemperature = const Value.absent(),
    Value<bool?> precipitation = const Value.absent(),
    int? displayMask,
  }) => WeatherRow(
    diaryId: diaryId ?? this.diaryId,
    condition: condition.present ? condition.value : this.condition,
    temperature: temperature.present ? temperature.value : this.temperature,
    minimumTemperature: minimumTemperature.present
        ? minimumTemperature.value
        : this.minimumTemperature,
    maximumTemperature: maximumTemperature.present
        ? maximumTemperature.value
        : this.maximumTemperature,
    precipitation: precipitation.present
        ? precipitation.value
        : this.precipitation,
    displayMask: displayMask ?? this.displayMask,
  );
  WeatherRow copyWithCompanion(WeatherEntriesCompanion data) {
    return WeatherRow(
      diaryId: data.diaryId.present ? data.diaryId.value : this.diaryId,
      condition: data.condition.present ? data.condition.value : this.condition,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      minimumTemperature: data.minimumTemperature.present
          ? data.minimumTemperature.value
          : this.minimumTemperature,
      maximumTemperature: data.maximumTemperature.present
          ? data.maximumTemperature.value
          : this.maximumTemperature,
      precipitation: data.precipitation.present
          ? data.precipitation.value
          : this.precipitation,
      displayMask: data.displayMask.present
          ? data.displayMask.value
          : this.displayMask,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeatherRow(')
          ..write('diaryId: $diaryId, ')
          ..write('condition: $condition, ')
          ..write('temperature: $temperature, ')
          ..write('minimumTemperature: $minimumTemperature, ')
          ..write('maximumTemperature: $maximumTemperature, ')
          ..write('precipitation: $precipitation, ')
          ..write('displayMask: $displayMask')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    diaryId,
    condition,
    temperature,
    minimumTemperature,
    maximumTemperature,
    precipitation,
    displayMask,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherRow &&
          other.diaryId == this.diaryId &&
          other.condition == this.condition &&
          other.temperature == this.temperature &&
          other.minimumTemperature == this.minimumTemperature &&
          other.maximumTemperature == this.maximumTemperature &&
          other.precipitation == this.precipitation &&
          other.displayMask == this.displayMask);
}

class WeatherEntriesCompanion extends UpdateCompanion<WeatherRow> {
  final Value<String> diaryId;
  final Value<String?> condition;
  final Value<double?> temperature;
  final Value<double?> minimumTemperature;
  final Value<double?> maximumTemperature;
  final Value<bool?> precipitation;
  final Value<int> displayMask;
  final Value<int> rowid;
  const WeatherEntriesCompanion({
    this.diaryId = const Value.absent(),
    this.condition = const Value.absent(),
    this.temperature = const Value.absent(),
    this.minimumTemperature = const Value.absent(),
    this.maximumTemperature = const Value.absent(),
    this.precipitation = const Value.absent(),
    this.displayMask = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeatherEntriesCompanion.insert({
    required String diaryId,
    this.condition = const Value.absent(),
    this.temperature = const Value.absent(),
    this.minimumTemperature = const Value.absent(),
    this.maximumTemperature = const Value.absent(),
    this.precipitation = const Value.absent(),
    this.displayMask = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : diaryId = Value(diaryId);
  static Insertable<WeatherRow> custom({
    Expression<String>? diaryId,
    Expression<String>? condition,
    Expression<double>? temperature,
    Expression<double>? minimumTemperature,
    Expression<double>? maximumTemperature,
    Expression<bool>? precipitation,
    Expression<int>? displayMask,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (diaryId != null) 'diary_id': diaryId,
      if (condition != null) 'condition': condition,
      if (temperature != null) 'temperature': temperature,
      if (minimumTemperature != null) 'minimum_temperature': minimumTemperature,
      if (maximumTemperature != null) 'maximum_temperature': maximumTemperature,
      if (precipitation != null) 'precipitation': precipitation,
      if (displayMask != null) 'display_mask': displayMask,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeatherEntriesCompanion copyWith({
    Value<String>? diaryId,
    Value<String?>? condition,
    Value<double?>? temperature,
    Value<double?>? minimumTemperature,
    Value<double?>? maximumTemperature,
    Value<bool?>? precipitation,
    Value<int>? displayMask,
    Value<int>? rowid,
  }) {
    return WeatherEntriesCompanion(
      diaryId: diaryId ?? this.diaryId,
      condition: condition ?? this.condition,
      temperature: temperature ?? this.temperature,
      minimumTemperature: minimumTemperature ?? this.minimumTemperature,
      maximumTemperature: maximumTemperature ?? this.maximumTemperature,
      precipitation: precipitation ?? this.precipitation,
      displayMask: displayMask ?? this.displayMask,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (diaryId.present) {
      map['diary_id'] = Variable<String>(diaryId.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (minimumTemperature.present) {
      map['minimum_temperature'] = Variable<double>(minimumTemperature.value);
    }
    if (maximumTemperature.present) {
      map['maximum_temperature'] = Variable<double>(maximumTemperature.value);
    }
    if (precipitation.present) {
      map['precipitation'] = Variable<bool>(precipitation.value);
    }
    if (displayMask.present) {
      map['display_mask'] = Variable<int>(displayMask.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherEntriesCompanion(')
          ..write('diaryId: $diaryId, ')
          ..write('condition: $condition, ')
          ..write('temperature: $temperature, ')
          ..write('minimumTemperature: $minimumTemperature, ')
          ..write('maximumTemperature: $maximumTemperature, ')
          ..write('precipitation: $precipitation, ')
          ..write('displayMask: $displayMask, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DraftEntriesTable extends DraftEntries
    with TableInfo<$DraftEntriesTable, DraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtEpochMeta = const VerificationMeta(
    'updatedAtEpoch',
  );
  @override
  late final GeneratedColumn<int> updatedAtEpoch = GeneratedColumn<int>(
    'updated_at_epoch',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payloadJson, updatedAtEpoch];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'draft_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at_epoch')) {
      context.handle(
        _updatedAtEpochMeta,
        updatedAtEpoch.isAcceptableOrUnknown(
          data['updated_at_epoch']!,
          _updatedAtEpochMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtEpochMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAtEpoch: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_epoch'],
      )!,
    );
  }

  @override
  $DraftEntriesTable createAlias(String alias) {
    return $DraftEntriesTable(attachedDatabase, alias);
  }
}

class DraftRow extends DataClass implements Insertable<DraftRow> {
  final String id;
  final String payloadJson;
  final int updatedAtEpoch;
  const DraftRow({
    required this.id,
    required this.payloadJson,
    required this.updatedAtEpoch,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at_epoch'] = Variable<int>(updatedAtEpoch);
    return map;
  }

  DraftEntriesCompanion toCompanion(bool nullToAbsent) {
    return DraftEntriesCompanion(
      id: Value(id),
      payloadJson: Value(payloadJson),
      updatedAtEpoch: Value(updatedAtEpoch),
    );
  }

  factory DraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftRow(
      id: serializer.fromJson<String>(json['id']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAtEpoch: serializer.fromJson<int>(json['updatedAtEpoch']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAtEpoch': serializer.toJson<int>(updatedAtEpoch),
    };
  }

  DraftRow copyWith({String? id, String? payloadJson, int? updatedAtEpoch}) =>
      DraftRow(
        id: id ?? this.id,
        payloadJson: payloadJson ?? this.payloadJson,
        updatedAtEpoch: updatedAtEpoch ?? this.updatedAtEpoch,
      );
  DraftRow copyWithCompanion(DraftEntriesCompanion data) {
    return DraftRow(
      id: data.id.present ? data.id.value : this.id,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAtEpoch: data.updatedAtEpoch.present
          ? data.updatedAtEpoch.value
          : this.updatedAtEpoch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftRow(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAtEpoch: $updatedAtEpoch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payloadJson, updatedAtEpoch);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftRow &&
          other.id == this.id &&
          other.payloadJson == this.payloadJson &&
          other.updatedAtEpoch == this.updatedAtEpoch);
}

class DraftEntriesCompanion extends UpdateCompanion<DraftRow> {
  final Value<String> id;
  final Value<String> payloadJson;
  final Value<int> updatedAtEpoch;
  final Value<int> rowid;
  const DraftEntriesCompanion({
    this.id = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAtEpoch = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DraftEntriesCompanion.insert({
    required String id,
    required String payloadJson,
    required int updatedAtEpoch,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payloadJson = Value(payloadJson),
       updatedAtEpoch = Value(updatedAtEpoch);
  static Insertable<DraftRow> custom({
    Expression<String>? id,
    Expression<String>? payloadJson,
    Expression<int>? updatedAtEpoch,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAtEpoch != null) 'updated_at_epoch': updatedAtEpoch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DraftEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? payloadJson,
    Value<int>? updatedAtEpoch,
    Value<int>? rowid,
  }) {
    return DraftEntriesCompanion(
      id: id ?? this.id,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAtEpoch: updatedAtEpoch ?? this.updatedAtEpoch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAtEpoch.present) {
      map['updated_at_epoch'] = Variable<int>(updatedAtEpoch.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftEntriesCompanion(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAtEpoch: $updatedAtEpoch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingEntriesTable extends SettingEntries
    with TableInfo<$SettingEntriesTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, valueJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setting_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
    );
  }

  @override
  $SettingEntriesTable createAlias(String alias) {
    return $SettingEntriesTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String valueJson;
  const SettingRow({required this.key, required this.valueJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    return map;
  }

  SettingEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingEntriesCompanion(
      key: Value(key),
      valueJson: Value(valueJson),
    );
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
    };
  }

  SettingRow copyWith({String? key, String? valueJson}) =>
      SettingRow(key: key ?? this.key, valueJson: valueJson ?? this.valueJson);
  SettingRow copyWithCompanion(SettingEntriesCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.valueJson == this.valueJson);
}

class SettingEntriesCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<int> rowid;
  const SettingEntriesCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingEntriesCompanion.insert({
    required String key,
    required String valueJson,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<int>? rowid,
  }) {
    return SettingEntriesCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingEntriesCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DiariesTable diaries = $DiariesTable(this);
  late final $MediaEntriesTable mediaEntries = $MediaEntriesTable(this);
  late final $WeatherEntriesTable weatherEntries = $WeatherEntriesTable(this);
  late final $DraftEntriesTable draftEntries = $DraftEntriesTable(this);
  late final $SettingEntriesTable settingEntries = $SettingEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    diaries,
    mediaEntries,
    weatherEntries,
    draftEntries,
    settingEntries,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'diaries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('media_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'diaries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('weather_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DiariesTableCreateCompanionBuilder =
    DiariesCompanion Function({
      required String id,
      required String entryDate,
      required int entryTimeMinutes,
      required int utcOffsetMinutes,
      Value<String?> headline,
      Value<String?> body,
      Value<String?> mood,
      Value<String> tagsJson,
      Value<String> companionsJson,
      required int createdAtEpoch,
      required int updatedAtEpoch,
      Value<int?> deletedAtEpoch,
      Value<int?> purgeAtEpoch,
      Value<int> rowid,
    });
typedef $$DiariesTableUpdateCompanionBuilder =
    DiariesCompanion Function({
      Value<String> id,
      Value<String> entryDate,
      Value<int> entryTimeMinutes,
      Value<int> utcOffsetMinutes,
      Value<String?> headline,
      Value<String?> body,
      Value<String?> mood,
      Value<String> tagsJson,
      Value<String> companionsJson,
      Value<int> createdAtEpoch,
      Value<int> updatedAtEpoch,
      Value<int?> deletedAtEpoch,
      Value<int?> purgeAtEpoch,
      Value<int> rowid,
    });

final class $$DiariesTableReferences
    extends BaseReferences<_$AppDatabase, $DiariesTable, DiaryRow> {
  $$DiariesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MediaEntriesTable, List<MediaRow>>
  _mediaEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaEntries,
    aliasName: 'diaries__id__media_entries__diary_id',
  );

  $$MediaEntriesTableProcessedTableManager get mediaEntriesRefs {
    final manager = $$MediaEntriesTableTableManager(
      $_db,
      $_db.mediaEntries,
    ).filter((f) => f.diaryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WeatherEntriesTable, List<WeatherRow>>
  _weatherEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.weatherEntries,
    aliasName: 'diaries__id__weather_entries__diary_id',
  );

  $$WeatherEntriesTableProcessedTableManager get weatherEntriesRefs {
    final manager = $$WeatherEntriesTableTableManager(
      $_db,
      $_db.weatherEntries,
    ).filter((f) => f.diaryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_weatherEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DiariesTableFilterComposer
    extends Composer<_$AppDatabase, $DiariesTable> {
  $$DiariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entryTimeMinutes => $composableBuilder(
    column: $table.entryTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headline => $composableBuilder(
    column: $table.headline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companionsJson => $composableBuilder(
    column: $table.companionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtEpoch => $composableBuilder(
    column: $table.createdAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtEpoch => $composableBuilder(
    column: $table.deletedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeAtEpoch => $composableBuilder(
    column: $table.purgeAtEpoch,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mediaEntriesRefs(
    Expression<bool> Function($$MediaEntriesTableFilterComposer f) f,
  ) {
    final $$MediaEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaEntries,
      getReferencedColumn: (t) => t.diaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaEntriesTableFilterComposer(
            $db: $db,
            $table: $db.mediaEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> weatherEntriesRefs(
    Expression<bool> Function($$WeatherEntriesTableFilterComposer f) f,
  ) {
    final $$WeatherEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weatherEntries,
      getReferencedColumn: (t) => t.diaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeatherEntriesTableFilterComposer(
            $db: $db,
            $table: $db.weatherEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiariesTableOrderingComposer
    extends Composer<_$AppDatabase, $DiariesTable> {
  $$DiariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryDate => $composableBuilder(
    column: $table.entryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entryTimeMinutes => $composableBuilder(
    column: $table.entryTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headline => $composableBuilder(
    column: $table.headline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companionsJson => $composableBuilder(
    column: $table.companionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtEpoch => $composableBuilder(
    column: $table.createdAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtEpoch => $composableBuilder(
    column: $table.deletedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeAtEpoch => $composableBuilder(
    column: $table.purgeAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DiariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiariesTable> {
  $$DiariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entryDate =>
      $composableBuilder(column: $table.entryDate, builder: (column) => column);

  GeneratedColumn<int> get entryTimeMinutes => $composableBuilder(
    column: $table.entryTimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get headline =>
      $composableBuilder(column: $table.headline, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get companionsJson => $composableBuilder(
    column: $table.companionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtEpoch => $composableBuilder(
    column: $table.createdAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtEpoch => $composableBuilder(
    column: $table.deletedAtEpoch,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purgeAtEpoch => $composableBuilder(
    column: $table.purgeAtEpoch,
    builder: (column) => column,
  );

  Expression<T> mediaEntriesRefs<T extends Object>(
    Expression<T> Function($$MediaEntriesTableAnnotationComposer a) f,
  ) {
    final $$MediaEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaEntries,
      getReferencedColumn: (t) => t.diaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> weatherEntriesRefs<T extends Object>(
    Expression<T> Function($$WeatherEntriesTableAnnotationComposer a) f,
  ) {
    final $$WeatherEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weatherEntries,
      getReferencedColumn: (t) => t.diaryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeatherEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.weatherEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiariesTable,
          DiaryRow,
          $$DiariesTableFilterComposer,
          $$DiariesTableOrderingComposer,
          $$DiariesTableAnnotationComposer,
          $$DiariesTableCreateCompanionBuilder,
          $$DiariesTableUpdateCompanionBuilder,
          (DiaryRow, $$DiariesTableReferences),
          DiaryRow,
          PrefetchHooks Function({
            bool mediaEntriesRefs,
            bool weatherEntriesRefs,
          })
        > {
  $$DiariesTableTableManager(_$AppDatabase db, $DiariesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entryDate = const Value.absent(),
                Value<int> entryTimeMinutes = const Value.absent(),
                Value<int> utcOffsetMinutes = const Value.absent(),
                Value<String?> headline = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String> companionsJson = const Value.absent(),
                Value<int> createdAtEpoch = const Value.absent(),
                Value<int> updatedAtEpoch = const Value.absent(),
                Value<int?> deletedAtEpoch = const Value.absent(),
                Value<int?> purgeAtEpoch = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiariesCompanion(
                id: id,
                entryDate: entryDate,
                entryTimeMinutes: entryTimeMinutes,
                utcOffsetMinutes: utcOffsetMinutes,
                headline: headline,
                body: body,
                mood: mood,
                tagsJson: tagsJson,
                companionsJson: companionsJson,
                createdAtEpoch: createdAtEpoch,
                updatedAtEpoch: updatedAtEpoch,
                deletedAtEpoch: deletedAtEpoch,
                purgeAtEpoch: purgeAtEpoch,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entryDate,
                required int entryTimeMinutes,
                required int utcOffsetMinutes,
                Value<String?> headline = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String> companionsJson = const Value.absent(),
                required int createdAtEpoch,
                required int updatedAtEpoch,
                Value<int?> deletedAtEpoch = const Value.absent(),
                Value<int?> purgeAtEpoch = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiariesCompanion.insert(
                id: id,
                entryDate: entryDate,
                entryTimeMinutes: entryTimeMinutes,
                utcOffsetMinutes: utcOffsetMinutes,
                headline: headline,
                body: body,
                mood: mood,
                tagsJson: tagsJson,
                companionsJson: companionsJson,
                createdAtEpoch: createdAtEpoch,
                updatedAtEpoch: updatedAtEpoch,
                deletedAtEpoch: deletedAtEpoch,
                purgeAtEpoch: purgeAtEpoch,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DiariesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({mediaEntriesRefs = false, weatherEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (mediaEntriesRefs) db.mediaEntries,
                    if (weatherEntriesRefs) db.weatherEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (mediaEntriesRefs)
                        await $_getPrefetchedData<
                          DiaryRow,
                          $DiariesTable,
                          MediaRow
                        >(
                          currentTable: table,
                          referencedTable: $$DiariesTableReferences
                              ._mediaEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DiariesTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.diaryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (weatherEntriesRefs)
                        await $_getPrefetchedData<
                          DiaryRow,
                          $DiariesTable,
                          WeatherRow
                        >(
                          currentTable: table,
                          referencedTable: $$DiariesTableReferences
                              ._weatherEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DiariesTableReferences(
                                db,
                                table,
                                p0,
                              ).weatherEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.diaryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DiariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiariesTable,
      DiaryRow,
      $$DiariesTableFilterComposer,
      $$DiariesTableOrderingComposer,
      $$DiariesTableAnnotationComposer,
      $$DiariesTableCreateCompanionBuilder,
      $$DiariesTableUpdateCompanionBuilder,
      (DiaryRow, $$DiariesTableReferences),
      DiaryRow,
      PrefetchHooks Function({bool mediaEntriesRefs, bool weatherEntriesRefs})
    >;
typedef $$MediaEntriesTableCreateCompanionBuilder =
    MediaEntriesCompanion Function({
      required String id,
      required String diaryId,
      required int sortOrder,
      required String kind,
      required String mimeType,
      required String encryptedPath,
      Value<String?> thumbnailPath,
      Value<String?> renderedPath,
      required String mediaKeyBase64,
      required int byteLength,
      Value<int?> width,
      Value<int?> height,
      Value<int?> durationMillis,
      Value<int?> representativeMillis,
      Value<String?> editHistoryJson,
      Value<int> editVersion,
      Value<int> rowid,
    });
typedef $$MediaEntriesTableUpdateCompanionBuilder =
    MediaEntriesCompanion Function({
      Value<String> id,
      Value<String> diaryId,
      Value<int> sortOrder,
      Value<String> kind,
      Value<String> mimeType,
      Value<String> encryptedPath,
      Value<String?> thumbnailPath,
      Value<String?> renderedPath,
      Value<String> mediaKeyBase64,
      Value<int> byteLength,
      Value<int?> width,
      Value<int?> height,
      Value<int?> durationMillis,
      Value<int?> representativeMillis,
      Value<String?> editHistoryJson,
      Value<int> editVersion,
      Value<int> rowid,
    });

final class $$MediaEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $MediaEntriesTable, MediaRow> {
  $$MediaEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DiariesTable _diaryIdTable(_$AppDatabase db) =>
      db.diaries.createAlias('media_entries__diary_id__diaries__id');

  $$DiariesTableProcessedTableManager get diaryId {
    final $_column = $_itemColumn<String>('diary_id')!;

    final manager = $$DiariesTableTableManager(
      $_db,
      $_db.diaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MediaEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MediaEntriesTable> {
  $$MediaEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedPath => $composableBuilder(
    column: $table.encryptedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get renderedPath => $composableBuilder(
    column: $table.renderedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaKeyBase64 => $composableBuilder(
    column: $table.mediaKeyBase64,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get representativeMillis => $composableBuilder(
    column: $table.representativeMillis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get editHistoryJson => $composableBuilder(
    column: $table.editHistoryJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editVersion => $composableBuilder(
    column: $table.editVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$DiariesTableFilterComposer get diaryId {
    final $$DiariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diaryId,
      referencedTable: $db.diaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiariesTableFilterComposer(
            $db: $db,
            $table: $db.diaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaEntriesTable> {
  $$MediaEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedPath => $composableBuilder(
    column: $table.encryptedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get renderedPath => $composableBuilder(
    column: $table.renderedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaKeyBase64 => $composableBuilder(
    column: $table.mediaKeyBase64,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get representativeMillis => $composableBuilder(
    column: $table.representativeMillis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editHistoryJson => $composableBuilder(
    column: $table.editHistoryJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editVersion => $composableBuilder(
    column: $table.editVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$DiariesTableOrderingComposer get diaryId {
    final $$DiariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diaryId,
      referencedTable: $db.diaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiariesTableOrderingComposer(
            $db: $db,
            $table: $db.diaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaEntriesTable> {
  $$MediaEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get encryptedPath => $composableBuilder(
    column: $table.encryptedPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get renderedPath => $composableBuilder(
    column: $table.renderedPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaKeyBase64 => $composableBuilder(
    column: $table.mediaKeyBase64,
    builder: (column) => column,
  );

  GeneratedColumn<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get durationMillis => $composableBuilder(
    column: $table.durationMillis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get representativeMillis => $composableBuilder(
    column: $table.representativeMillis,
    builder: (column) => column,
  );

  GeneratedColumn<String> get editHistoryJson => $composableBuilder(
    column: $table.editHistoryJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get editVersion => $composableBuilder(
    column: $table.editVersion,
    builder: (column) => column,
  );

  $$DiariesTableAnnotationComposer get diaryId {
    final $$DiariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diaryId,
      referencedTable: $db.diaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiariesTableAnnotationComposer(
            $db: $db,
            $table: $db.diaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaEntriesTable,
          MediaRow,
          $$MediaEntriesTableFilterComposer,
          $$MediaEntriesTableOrderingComposer,
          $$MediaEntriesTableAnnotationComposer,
          $$MediaEntriesTableCreateCompanionBuilder,
          $$MediaEntriesTableUpdateCompanionBuilder,
          (MediaRow, $$MediaEntriesTableReferences),
          MediaRow,
          PrefetchHooks Function({bool diaryId})
        > {
  $$MediaEntriesTableTableManager(_$AppDatabase db, $MediaEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> diaryId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<String> encryptedPath = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> renderedPath = const Value.absent(),
                Value<String> mediaKeyBase64 = const Value.absent(),
                Value<int> byteLength = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> durationMillis = const Value.absent(),
                Value<int?> representativeMillis = const Value.absent(),
                Value<String?> editHistoryJson = const Value.absent(),
                Value<int> editVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaEntriesCompanion(
                id: id,
                diaryId: diaryId,
                sortOrder: sortOrder,
                kind: kind,
                mimeType: mimeType,
                encryptedPath: encryptedPath,
                thumbnailPath: thumbnailPath,
                renderedPath: renderedPath,
                mediaKeyBase64: mediaKeyBase64,
                byteLength: byteLength,
                width: width,
                height: height,
                durationMillis: durationMillis,
                representativeMillis: representativeMillis,
                editHistoryJson: editHistoryJson,
                editVersion: editVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String diaryId,
                required int sortOrder,
                required String kind,
                required String mimeType,
                required String encryptedPath,
                Value<String?> thumbnailPath = const Value.absent(),
                Value<String?> renderedPath = const Value.absent(),
                required String mediaKeyBase64,
                required int byteLength,
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<int?> durationMillis = const Value.absent(),
                Value<int?> representativeMillis = const Value.absent(),
                Value<String?> editHistoryJson = const Value.absent(),
                Value<int> editVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaEntriesCompanion.insert(
                id: id,
                diaryId: diaryId,
                sortOrder: sortOrder,
                kind: kind,
                mimeType: mimeType,
                encryptedPath: encryptedPath,
                thumbnailPath: thumbnailPath,
                renderedPath: renderedPath,
                mediaKeyBase64: mediaKeyBase64,
                byteLength: byteLength,
                width: width,
                height: height,
                durationMillis: durationMillis,
                representativeMillis: representativeMillis,
                editHistoryJson: editHistoryJson,
                editVersion: editVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MediaEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({diaryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (diaryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.diaryId,
                                referencedTable: $$MediaEntriesTableReferences
                                    ._diaryIdTable(db),
                                referencedColumn: $$MediaEntriesTableReferences
                                    ._diaryIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MediaEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaEntriesTable,
      MediaRow,
      $$MediaEntriesTableFilterComposer,
      $$MediaEntriesTableOrderingComposer,
      $$MediaEntriesTableAnnotationComposer,
      $$MediaEntriesTableCreateCompanionBuilder,
      $$MediaEntriesTableUpdateCompanionBuilder,
      (MediaRow, $$MediaEntriesTableReferences),
      MediaRow,
      PrefetchHooks Function({bool diaryId})
    >;
typedef $$WeatherEntriesTableCreateCompanionBuilder =
    WeatherEntriesCompanion Function({
      required String diaryId,
      Value<String?> condition,
      Value<double?> temperature,
      Value<double?> minimumTemperature,
      Value<double?> maximumTemperature,
      Value<bool?> precipitation,
      Value<int> displayMask,
      Value<int> rowid,
    });
typedef $$WeatherEntriesTableUpdateCompanionBuilder =
    WeatherEntriesCompanion Function({
      Value<String> diaryId,
      Value<String?> condition,
      Value<double?> temperature,
      Value<double?> minimumTemperature,
      Value<double?> maximumTemperature,
      Value<bool?> precipitation,
      Value<int> displayMask,
      Value<int> rowid,
    });

final class $$WeatherEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $WeatherEntriesTable, WeatherRow> {
  $$WeatherEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DiariesTable _diaryIdTable(_$AppDatabase db) =>
      db.diaries.createAlias('weather_entries__diary_id__diaries__id');

  $$DiariesTableProcessedTableManager get diaryId {
    final $_column = $_itemColumn<String>('diary_id')!;

    final manager = $$DiariesTableTableManager(
      $_db,
      $_db.diaries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_diaryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WeatherEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeatherEntriesTable> {
  $$WeatherEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minimumTemperature => $composableBuilder(
    column: $table.minimumTemperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maximumTemperature => $composableBuilder(
    column: $table.maximumTemperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get precipitation => $composableBuilder(
    column: $table.precipitation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayMask => $composableBuilder(
    column: $table.displayMask,
    builder: (column) => ColumnFilters(column),
  );

  $$DiariesTableFilterComposer get diaryId {
    final $$DiariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diaryId,
      referencedTable: $db.diaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiariesTableFilterComposer(
            $db: $db,
            $table: $db.diaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeatherEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeatherEntriesTable> {
  $$WeatherEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minimumTemperature => $composableBuilder(
    column: $table.minimumTemperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maximumTemperature => $composableBuilder(
    column: $table.maximumTemperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get precipitation => $composableBuilder(
    column: $table.precipitation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayMask => $composableBuilder(
    column: $table.displayMask,
    builder: (column) => ColumnOrderings(column),
  );

  $$DiariesTableOrderingComposer get diaryId {
    final $$DiariesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diaryId,
      referencedTable: $db.diaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiariesTableOrderingComposer(
            $db: $db,
            $table: $db.diaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeatherEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeatherEntriesTable> {
  $$WeatherEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minimumTemperature => $composableBuilder(
    column: $table.minimumTemperature,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maximumTemperature => $composableBuilder(
    column: $table.maximumTemperature,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get precipitation => $composableBuilder(
    column: $table.precipitation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get displayMask => $composableBuilder(
    column: $table.displayMask,
    builder: (column) => column,
  );

  $$DiariesTableAnnotationComposer get diaryId {
    final $$DiariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.diaryId,
      referencedTable: $db.diaries,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiariesTableAnnotationComposer(
            $db: $db,
            $table: $db.diaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeatherEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeatherEntriesTable,
          WeatherRow,
          $$WeatherEntriesTableFilterComposer,
          $$WeatherEntriesTableOrderingComposer,
          $$WeatherEntriesTableAnnotationComposer,
          $$WeatherEntriesTableCreateCompanionBuilder,
          $$WeatherEntriesTableUpdateCompanionBuilder,
          (WeatherRow, $$WeatherEntriesTableReferences),
          WeatherRow,
          PrefetchHooks Function({bool diaryId})
        > {
  $$WeatherEntriesTableTableManager(
    _$AppDatabase db,
    $WeatherEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeatherEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeatherEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeatherEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> diaryId = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<double?> temperature = const Value.absent(),
                Value<double?> minimumTemperature = const Value.absent(),
                Value<double?> maximumTemperature = const Value.absent(),
                Value<bool?> precipitation = const Value.absent(),
                Value<int> displayMask = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeatherEntriesCompanion(
                diaryId: diaryId,
                condition: condition,
                temperature: temperature,
                minimumTemperature: minimumTemperature,
                maximumTemperature: maximumTemperature,
                precipitation: precipitation,
                displayMask: displayMask,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String diaryId,
                Value<String?> condition = const Value.absent(),
                Value<double?> temperature = const Value.absent(),
                Value<double?> minimumTemperature = const Value.absent(),
                Value<double?> maximumTemperature = const Value.absent(),
                Value<bool?> precipitation = const Value.absent(),
                Value<int> displayMask = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeatherEntriesCompanion.insert(
                diaryId: diaryId,
                condition: condition,
                temperature: temperature,
                minimumTemperature: minimumTemperature,
                maximumTemperature: maximumTemperature,
                precipitation: precipitation,
                displayMask: displayMask,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WeatherEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({diaryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (diaryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.diaryId,
                                referencedTable: $$WeatherEntriesTableReferences
                                    ._diaryIdTable(db),
                                referencedColumn:
                                    $$WeatherEntriesTableReferences
                                        ._diaryIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WeatherEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeatherEntriesTable,
      WeatherRow,
      $$WeatherEntriesTableFilterComposer,
      $$WeatherEntriesTableOrderingComposer,
      $$WeatherEntriesTableAnnotationComposer,
      $$WeatherEntriesTableCreateCompanionBuilder,
      $$WeatherEntriesTableUpdateCompanionBuilder,
      (WeatherRow, $$WeatherEntriesTableReferences),
      WeatherRow,
      PrefetchHooks Function({bool diaryId})
    >;
typedef $$DraftEntriesTableCreateCompanionBuilder =
    DraftEntriesCompanion Function({
      required String id,
      required String payloadJson,
      required int updatedAtEpoch,
      Value<int> rowid,
    });
typedef $$DraftEntriesTableUpdateCompanionBuilder =
    DraftEntriesCompanion Function({
      Value<String> id,
      Value<String> payloadJson,
      Value<int> updatedAtEpoch,
      Value<int> rowid,
    });

class $$DraftEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DraftEntriesTable> {
  $$DraftEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftEntriesTable> {
  $$DraftEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftEntriesTable> {
  $$DraftEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtEpoch => $composableBuilder(
    column: $table.updatedAtEpoch,
    builder: (column) => column,
  );
}

class $$DraftEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DraftEntriesTable,
          DraftRow,
          $$DraftEntriesTableFilterComposer,
          $$DraftEntriesTableOrderingComposer,
          $$DraftEntriesTableAnnotationComposer,
          $$DraftEntriesTableCreateCompanionBuilder,
          $$DraftEntriesTableUpdateCompanionBuilder,
          (
            DraftRow,
            BaseReferences<_$AppDatabase, $DraftEntriesTable, DraftRow>,
          ),
          DraftRow,
          PrefetchHooks Function()
        > {
  $$DraftEntriesTableTableManager(_$AppDatabase db, $DraftEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<int> updatedAtEpoch = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftEntriesCompanion(
                id: id,
                payloadJson: payloadJson,
                updatedAtEpoch: updatedAtEpoch,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payloadJson,
                required int updatedAtEpoch,
                Value<int> rowid = const Value.absent(),
              }) => DraftEntriesCompanion.insert(
                id: id,
                payloadJson: payloadJson,
                updatedAtEpoch: updatedAtEpoch,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DraftEntriesTable,
      DraftRow,
      $$DraftEntriesTableFilterComposer,
      $$DraftEntriesTableOrderingComposer,
      $$DraftEntriesTableAnnotationComposer,
      $$DraftEntriesTableCreateCompanionBuilder,
      $$DraftEntriesTableUpdateCompanionBuilder,
      (DraftRow, BaseReferences<_$AppDatabase, $DraftEntriesTable, DraftRow>),
      DraftRow,
      PrefetchHooks Function()
    >;
typedef $$SettingEntriesTableCreateCompanionBuilder =
    SettingEntriesCompanion Function({
      required String key,
      required String valueJson,
      Value<int> rowid,
    });
typedef $$SettingEntriesTableUpdateCompanionBuilder =
    SettingEntriesCompanion Function({
      Value<String> key,
      Value<String> valueJson,
      Value<int> rowid,
    });

class $$SettingEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingEntriesTable> {
  $$SettingEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);
}

class $$SettingEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingEntriesTable,
          SettingRow,
          $$SettingEntriesTableFilterComposer,
          $$SettingEntriesTableOrderingComposer,
          $$SettingEntriesTableAnnotationComposer,
          $$SettingEntriesTableCreateCompanionBuilder,
          $$SettingEntriesTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingEntriesTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingEntriesTableTableManager(
    _$AppDatabase db,
    $SettingEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingEntriesCompanion(
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueJson,
                Value<int> rowid = const Value.absent(),
              }) => SettingEntriesCompanion.insert(
                key: key,
                valueJson: valueJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingEntriesTable,
      SettingRow,
      $$SettingEntriesTableFilterComposer,
      $$SettingEntriesTableOrderingComposer,
      $$SettingEntriesTableAnnotationComposer,
      $$SettingEntriesTableCreateCompanionBuilder,
      $$SettingEntriesTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $SettingEntriesTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DiariesTableTableManager get diaries =>
      $$DiariesTableTableManager(_db, _db.diaries);
  $$MediaEntriesTableTableManager get mediaEntries =>
      $$MediaEntriesTableTableManager(_db, _db.mediaEntries);
  $$WeatherEntriesTableTableManager get weatherEntries =>
      $$WeatherEntriesTableTableManager(_db, _db.weatherEntries);
  $$DraftEntriesTableTableManager get draftEntries =>
      $$DraftEntriesTableTableManager(_db, _db.draftEntries);
  $$SettingEntriesTableTableManager get settingEntries =>
      $$SettingEntriesTableTableManager(_db, _db.settingEntries);
}
