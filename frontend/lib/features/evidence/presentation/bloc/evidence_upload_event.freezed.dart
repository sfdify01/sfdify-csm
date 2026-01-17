// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'evidence_upload_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EvidenceUploadEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvidenceUploadEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EvidenceUploadEvent()';
}


}

/// @nodoc
class $EvidenceUploadEventCopyWith<$Res>  {
$EvidenceUploadEventCopyWith(EvidenceUploadEvent _, $Res Function(EvidenceUploadEvent) __);
}


/// Adds pattern-matching-related methods to [EvidenceUploadEvent].
extension EvidenceUploadEventPatterns on EvidenceUploadEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EvidenceUploadFileSelected value)?  fileSelected,TResult Function( EvidenceUploadDescriptionChanged value)?  descriptionChanged,TResult Function( EvidenceUploadSubmitted value)?  submitted,TResult Function( EvidenceUploadCancelled value)?  cancelled,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EvidenceUploadFileSelected() when fileSelected != null:
return fileSelected(_that);case EvidenceUploadDescriptionChanged() when descriptionChanged != null:
return descriptionChanged(_that);case EvidenceUploadSubmitted() when submitted != null:
return submitted(_that);case EvidenceUploadCancelled() when cancelled != null:
return cancelled(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EvidenceUploadFileSelected value)  fileSelected,required TResult Function( EvidenceUploadDescriptionChanged value)  descriptionChanged,required TResult Function( EvidenceUploadSubmitted value)  submitted,required TResult Function( EvidenceUploadCancelled value)  cancelled,}){
final _that = this;
switch (_that) {
case EvidenceUploadFileSelected():
return fileSelected(_that);case EvidenceUploadDescriptionChanged():
return descriptionChanged(_that);case EvidenceUploadSubmitted():
return submitted(_that);case EvidenceUploadCancelled():
return cancelled(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EvidenceUploadFileSelected value)?  fileSelected,TResult? Function( EvidenceUploadDescriptionChanged value)?  descriptionChanged,TResult? Function( EvidenceUploadSubmitted value)?  submitted,TResult? Function( EvidenceUploadCancelled value)?  cancelled,}){
final _that = this;
switch (_that) {
case EvidenceUploadFileSelected() when fileSelected != null:
return fileSelected(_that);case EvidenceUploadDescriptionChanged() when descriptionChanged != null:
return descriptionChanged(_that);case EvidenceUploadSubmitted() when submitted != null:
return submitted(_that);case EvidenceUploadCancelled() when cancelled != null:
return cancelled(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String filename,  int fileSize,  String mimeType,  List<int> bytes)?  fileSelected,TResult Function( String description)?  descriptionChanged,TResult Function( String disputeId)?  submitted,TResult Function()?  cancelled,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EvidenceUploadFileSelected() when fileSelected != null:
return fileSelected(_that.filename,_that.fileSize,_that.mimeType,_that.bytes);case EvidenceUploadDescriptionChanged() when descriptionChanged != null:
return descriptionChanged(_that.description);case EvidenceUploadSubmitted() when submitted != null:
return submitted(_that.disputeId);case EvidenceUploadCancelled() when cancelled != null:
return cancelled();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String filename,  int fileSize,  String mimeType,  List<int> bytes)  fileSelected,required TResult Function( String description)  descriptionChanged,required TResult Function( String disputeId)  submitted,required TResult Function()  cancelled,}) {final _that = this;
switch (_that) {
case EvidenceUploadFileSelected():
return fileSelected(_that.filename,_that.fileSize,_that.mimeType,_that.bytes);case EvidenceUploadDescriptionChanged():
return descriptionChanged(_that.description);case EvidenceUploadSubmitted():
return submitted(_that.disputeId);case EvidenceUploadCancelled():
return cancelled();}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String filename,  int fileSize,  String mimeType,  List<int> bytes)?  fileSelected,TResult? Function( String description)?  descriptionChanged,TResult? Function( String disputeId)?  submitted,TResult? Function()?  cancelled,}) {final _that = this;
switch (_that) {
case EvidenceUploadFileSelected() when fileSelected != null:
return fileSelected(_that.filename,_that.fileSize,_that.mimeType,_that.bytes);case EvidenceUploadDescriptionChanged() when descriptionChanged != null:
return descriptionChanged(_that.description);case EvidenceUploadSubmitted() when submitted != null:
return submitted(_that.disputeId);case EvidenceUploadCancelled() when cancelled != null:
return cancelled();case _:
  return null;

}
}

}

/// @nodoc


class EvidenceUploadFileSelected implements EvidenceUploadEvent {
  const EvidenceUploadFileSelected({required this.filename, required this.fileSize, required this.mimeType, required final  List<int> bytes}): _bytes = bytes;
  

 final  String filename;
 final  int fileSize;
 final  String mimeType;
 final  List<int> _bytes;
 List<int> get bytes {
  if (_bytes is EqualUnmodifiableListView) return _bytes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bytes);
}


/// Create a copy of EvidenceUploadEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EvidenceUploadFileSelectedCopyWith<EvidenceUploadFileSelected> get copyWith => _$EvidenceUploadFileSelectedCopyWithImpl<EvidenceUploadFileSelected>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvidenceUploadFileSelected&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&const DeepCollectionEquality().equals(other._bytes, _bytes));
}


@override
int get hashCode => Object.hash(runtimeType,filename,fileSize,mimeType,const DeepCollectionEquality().hash(_bytes));

@override
String toString() {
  return 'EvidenceUploadEvent.fileSelected(filename: $filename, fileSize: $fileSize, mimeType: $mimeType, bytes: $bytes)';
}


}

/// @nodoc
abstract mixin class $EvidenceUploadFileSelectedCopyWith<$Res> implements $EvidenceUploadEventCopyWith<$Res> {
  factory $EvidenceUploadFileSelectedCopyWith(EvidenceUploadFileSelected value, $Res Function(EvidenceUploadFileSelected) _then) = _$EvidenceUploadFileSelectedCopyWithImpl;
@useResult
$Res call({
 String filename, int fileSize, String mimeType, List<int> bytes
});




}
/// @nodoc
class _$EvidenceUploadFileSelectedCopyWithImpl<$Res>
    implements $EvidenceUploadFileSelectedCopyWith<$Res> {
  _$EvidenceUploadFileSelectedCopyWithImpl(this._self, this._then);

  final EvidenceUploadFileSelected _self;
  final $Res Function(EvidenceUploadFileSelected) _then;

/// Create a copy of EvidenceUploadEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? filename = null,Object? fileSize = null,Object? mimeType = null,Object? bytes = null,}) {
  return _then(EvidenceUploadFileSelected(
filename: null == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,bytes: null == bytes ? _self._bytes : bytes // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

/// @nodoc


class EvidenceUploadDescriptionChanged implements EvidenceUploadEvent {
  const EvidenceUploadDescriptionChanged(this.description);
  

 final  String description;

/// Create a copy of EvidenceUploadEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EvidenceUploadDescriptionChangedCopyWith<EvidenceUploadDescriptionChanged> get copyWith => _$EvidenceUploadDescriptionChangedCopyWithImpl<EvidenceUploadDescriptionChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvidenceUploadDescriptionChanged&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,description);

@override
String toString() {
  return 'EvidenceUploadEvent.descriptionChanged(description: $description)';
}


}

/// @nodoc
abstract mixin class $EvidenceUploadDescriptionChangedCopyWith<$Res> implements $EvidenceUploadEventCopyWith<$Res> {
  factory $EvidenceUploadDescriptionChangedCopyWith(EvidenceUploadDescriptionChanged value, $Res Function(EvidenceUploadDescriptionChanged) _then) = _$EvidenceUploadDescriptionChangedCopyWithImpl;
@useResult
$Res call({
 String description
});




}
/// @nodoc
class _$EvidenceUploadDescriptionChangedCopyWithImpl<$Res>
    implements $EvidenceUploadDescriptionChangedCopyWith<$Res> {
  _$EvidenceUploadDescriptionChangedCopyWithImpl(this._self, this._then);

  final EvidenceUploadDescriptionChanged _self;
  final $Res Function(EvidenceUploadDescriptionChanged) _then;

/// Create a copy of EvidenceUploadEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? description = null,}) {
  return _then(EvidenceUploadDescriptionChanged(
null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class EvidenceUploadSubmitted implements EvidenceUploadEvent {
  const EvidenceUploadSubmitted({required this.disputeId});
  

 final  String disputeId;

/// Create a copy of EvidenceUploadEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EvidenceUploadSubmittedCopyWith<EvidenceUploadSubmitted> get copyWith => _$EvidenceUploadSubmittedCopyWithImpl<EvidenceUploadSubmitted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvidenceUploadSubmitted&&(identical(other.disputeId, disputeId) || other.disputeId == disputeId));
}


@override
int get hashCode => Object.hash(runtimeType,disputeId);

@override
String toString() {
  return 'EvidenceUploadEvent.submitted(disputeId: $disputeId)';
}


}

/// @nodoc
abstract mixin class $EvidenceUploadSubmittedCopyWith<$Res> implements $EvidenceUploadEventCopyWith<$Res> {
  factory $EvidenceUploadSubmittedCopyWith(EvidenceUploadSubmitted value, $Res Function(EvidenceUploadSubmitted) _then) = _$EvidenceUploadSubmittedCopyWithImpl;
@useResult
$Res call({
 String disputeId
});




}
/// @nodoc
class _$EvidenceUploadSubmittedCopyWithImpl<$Res>
    implements $EvidenceUploadSubmittedCopyWith<$Res> {
  _$EvidenceUploadSubmittedCopyWithImpl(this._self, this._then);

  final EvidenceUploadSubmitted _self;
  final $Res Function(EvidenceUploadSubmitted) _then;

/// Create a copy of EvidenceUploadEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? disputeId = null,}) {
  return _then(EvidenceUploadSubmitted(
disputeId: null == disputeId ? _self.disputeId : disputeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class EvidenceUploadCancelled implements EvidenceUploadEvent {
  const EvidenceUploadCancelled();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvidenceUploadCancelled);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EvidenceUploadEvent.cancelled()';
}


}




// dart format on
