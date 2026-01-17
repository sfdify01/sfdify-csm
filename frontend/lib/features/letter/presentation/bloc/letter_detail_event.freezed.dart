// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'letter_detail_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LetterDetailEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterDetailEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LetterDetailEvent()';
}


}

/// @nodoc
class $LetterDetailEventCopyWith<$Res>  {
$LetterDetailEventCopyWith(LetterDetailEvent _, $Res Function(LetterDetailEvent) __);
}


/// Adds pattern-matching-related methods to [LetterDetailEvent].
extension LetterDetailEventPatterns on LetterDetailEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LetterDetailLoadRequested value)?  loadRequested,TResult Function( LetterDetailRefreshRequested value)?  refreshRequested,TResult Function( LetterDetailApproveRequested value)?  approveRequested,TResult Function( LetterDetailSendRequested value)?  sendRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LetterDetailLoadRequested() when loadRequested != null:
return loadRequested(_that);case LetterDetailRefreshRequested() when refreshRequested != null:
return refreshRequested(_that);case LetterDetailApproveRequested() when approveRequested != null:
return approveRequested(_that);case LetterDetailSendRequested() when sendRequested != null:
return sendRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LetterDetailLoadRequested value)  loadRequested,required TResult Function( LetterDetailRefreshRequested value)  refreshRequested,required TResult Function( LetterDetailApproveRequested value)  approveRequested,required TResult Function( LetterDetailSendRequested value)  sendRequested,}){
final _that = this;
switch (_that) {
case LetterDetailLoadRequested():
return loadRequested(_that);case LetterDetailRefreshRequested():
return refreshRequested(_that);case LetterDetailApproveRequested():
return approveRequested(_that);case LetterDetailSendRequested():
return sendRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LetterDetailLoadRequested value)?  loadRequested,TResult? Function( LetterDetailRefreshRequested value)?  refreshRequested,TResult? Function( LetterDetailApproveRequested value)?  approveRequested,TResult? Function( LetterDetailSendRequested value)?  sendRequested,}){
final _that = this;
switch (_that) {
case LetterDetailLoadRequested() when loadRequested != null:
return loadRequested(_that);case LetterDetailRefreshRequested() when refreshRequested != null:
return refreshRequested(_that);case LetterDetailApproveRequested() when approveRequested != null:
return approveRequested(_that);case LetterDetailSendRequested() when sendRequested != null:
return sendRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String letterId)?  loadRequested,TResult Function()?  refreshRequested,TResult Function()?  approveRequested,TResult Function()?  sendRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LetterDetailLoadRequested() when loadRequested != null:
return loadRequested(_that.letterId);case LetterDetailRefreshRequested() when refreshRequested != null:
return refreshRequested();case LetterDetailApproveRequested() when approveRequested != null:
return approveRequested();case LetterDetailSendRequested() when sendRequested != null:
return sendRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String letterId)  loadRequested,required TResult Function()  refreshRequested,required TResult Function()  approveRequested,required TResult Function()  sendRequested,}) {final _that = this;
switch (_that) {
case LetterDetailLoadRequested():
return loadRequested(_that.letterId);case LetterDetailRefreshRequested():
return refreshRequested();case LetterDetailApproveRequested():
return approveRequested();case LetterDetailSendRequested():
return sendRequested();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String letterId)?  loadRequested,TResult? Function()?  refreshRequested,TResult? Function()?  approveRequested,TResult? Function()?  sendRequested,}) {final _that = this;
switch (_that) {
case LetterDetailLoadRequested() when loadRequested != null:
return loadRequested(_that.letterId);case LetterDetailRefreshRequested() when refreshRequested != null:
return refreshRequested();case LetterDetailApproveRequested() when approveRequested != null:
return approveRequested();case LetterDetailSendRequested() when sendRequested != null:
return sendRequested();case _:
  return null;

}
}

}

/// @nodoc


class LetterDetailLoadRequested implements LetterDetailEvent {
  const LetterDetailLoadRequested(this.letterId);
  

 final  String letterId;

/// Create a copy of LetterDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LetterDetailLoadRequestedCopyWith<LetterDetailLoadRequested> get copyWith => _$LetterDetailLoadRequestedCopyWithImpl<LetterDetailLoadRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterDetailLoadRequested&&(identical(other.letterId, letterId) || other.letterId == letterId));
}


@override
int get hashCode => Object.hash(runtimeType,letterId);

@override
String toString() {
  return 'LetterDetailEvent.loadRequested(letterId: $letterId)';
}


}

/// @nodoc
abstract mixin class $LetterDetailLoadRequestedCopyWith<$Res> implements $LetterDetailEventCopyWith<$Res> {
  factory $LetterDetailLoadRequestedCopyWith(LetterDetailLoadRequested value, $Res Function(LetterDetailLoadRequested) _then) = _$LetterDetailLoadRequestedCopyWithImpl;
@useResult
$Res call({
 String letterId
});




}
/// @nodoc
class _$LetterDetailLoadRequestedCopyWithImpl<$Res>
    implements $LetterDetailLoadRequestedCopyWith<$Res> {
  _$LetterDetailLoadRequestedCopyWithImpl(this._self, this._then);

  final LetterDetailLoadRequested _self;
  final $Res Function(LetterDetailLoadRequested) _then;

/// Create a copy of LetterDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? letterId = null,}) {
  return _then(LetterDetailLoadRequested(
null == letterId ? _self.letterId : letterId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LetterDetailRefreshRequested implements LetterDetailEvent {
  const LetterDetailRefreshRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterDetailRefreshRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LetterDetailEvent.refreshRequested()';
}


}




/// @nodoc


class LetterDetailApproveRequested implements LetterDetailEvent {
  const LetterDetailApproveRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterDetailApproveRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LetterDetailEvent.approveRequested()';
}


}




/// @nodoc


class LetterDetailSendRequested implements LetterDetailEvent {
  const LetterDetailSendRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterDetailSendRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LetterDetailEvent.sendRequested()';
}


}




// dart format on
