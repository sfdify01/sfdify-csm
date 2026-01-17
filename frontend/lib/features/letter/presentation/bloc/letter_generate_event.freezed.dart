// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'letter_generate_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LetterGenerateEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterGenerateEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LetterGenerateEvent()';
}


}

/// @nodoc
class $LetterGenerateEventCopyWith<$Res>  {
$LetterGenerateEventCopyWith(LetterGenerateEvent _, $Res Function(LetterGenerateEvent) __);
}


/// Adds pattern-matching-related methods to [LetterGenerateEvent].
extension LetterGenerateEventPatterns on LetterGenerateEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LetterGenerateLoadRequested value)?  loadRequested,TResult Function( LetterGenerateTemplateChanged value)?  templateChanged,TResult Function( LetterGenerateMailTypeChanged value)?  mailTypeChanged,TResult Function( LetterGenerateSubmitted value)?  submitted,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LetterGenerateLoadRequested() when loadRequested != null:
return loadRequested(_that);case LetterGenerateTemplateChanged() when templateChanged != null:
return templateChanged(_that);case LetterGenerateMailTypeChanged() when mailTypeChanged != null:
return mailTypeChanged(_that);case LetterGenerateSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LetterGenerateLoadRequested value)  loadRequested,required TResult Function( LetterGenerateTemplateChanged value)  templateChanged,required TResult Function( LetterGenerateMailTypeChanged value)  mailTypeChanged,required TResult Function( LetterGenerateSubmitted value)  submitted,}){
final _that = this;
switch (_that) {
case LetterGenerateLoadRequested():
return loadRequested(_that);case LetterGenerateTemplateChanged():
return templateChanged(_that);case LetterGenerateMailTypeChanged():
return mailTypeChanged(_that);case LetterGenerateSubmitted():
return submitted(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LetterGenerateLoadRequested value)?  loadRequested,TResult? Function( LetterGenerateTemplateChanged value)?  templateChanged,TResult? Function( LetterGenerateMailTypeChanged value)?  mailTypeChanged,TResult? Function( LetterGenerateSubmitted value)?  submitted,}){
final _that = this;
switch (_that) {
case LetterGenerateLoadRequested() when loadRequested != null:
return loadRequested(_that);case LetterGenerateTemplateChanged() when templateChanged != null:
return templateChanged(_that);case LetterGenerateMailTypeChanged() when mailTypeChanged != null:
return mailTypeChanged(_that);case LetterGenerateSubmitted() when submitted != null:
return submitted(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String disputeId)?  loadRequested,TResult Function( String templateId)?  templateChanged,TResult Function( String mailType)?  mailTypeChanged,TResult Function()?  submitted,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LetterGenerateLoadRequested() when loadRequested != null:
return loadRequested(_that.disputeId);case LetterGenerateTemplateChanged() when templateChanged != null:
return templateChanged(_that.templateId);case LetterGenerateMailTypeChanged() when mailTypeChanged != null:
return mailTypeChanged(_that.mailType);case LetterGenerateSubmitted() when submitted != null:
return submitted();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String disputeId)  loadRequested,required TResult Function( String templateId)  templateChanged,required TResult Function( String mailType)  mailTypeChanged,required TResult Function()  submitted,}) {final _that = this;
switch (_that) {
case LetterGenerateLoadRequested():
return loadRequested(_that.disputeId);case LetterGenerateTemplateChanged():
return templateChanged(_that.templateId);case LetterGenerateMailTypeChanged():
return mailTypeChanged(_that.mailType);case LetterGenerateSubmitted():
return submitted();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String disputeId)?  loadRequested,TResult? Function( String templateId)?  templateChanged,TResult? Function( String mailType)?  mailTypeChanged,TResult? Function()?  submitted,}) {final _that = this;
switch (_that) {
case LetterGenerateLoadRequested() when loadRequested != null:
return loadRequested(_that.disputeId);case LetterGenerateTemplateChanged() when templateChanged != null:
return templateChanged(_that.templateId);case LetterGenerateMailTypeChanged() when mailTypeChanged != null:
return mailTypeChanged(_that.mailType);case LetterGenerateSubmitted() when submitted != null:
return submitted();case _:
  return null;

}
}

}

/// @nodoc


class LetterGenerateLoadRequested implements LetterGenerateEvent {
  const LetterGenerateLoadRequested(this.disputeId);
  

 final  String disputeId;

/// Create a copy of LetterGenerateEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LetterGenerateLoadRequestedCopyWith<LetterGenerateLoadRequested> get copyWith => _$LetterGenerateLoadRequestedCopyWithImpl<LetterGenerateLoadRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterGenerateLoadRequested&&(identical(other.disputeId, disputeId) || other.disputeId == disputeId));
}


@override
int get hashCode => Object.hash(runtimeType,disputeId);

@override
String toString() {
  return 'LetterGenerateEvent.loadRequested(disputeId: $disputeId)';
}


}

/// @nodoc
abstract mixin class $LetterGenerateLoadRequestedCopyWith<$Res> implements $LetterGenerateEventCopyWith<$Res> {
  factory $LetterGenerateLoadRequestedCopyWith(LetterGenerateLoadRequested value, $Res Function(LetterGenerateLoadRequested) _then) = _$LetterGenerateLoadRequestedCopyWithImpl;
@useResult
$Res call({
 String disputeId
});




}
/// @nodoc
class _$LetterGenerateLoadRequestedCopyWithImpl<$Res>
    implements $LetterGenerateLoadRequestedCopyWith<$Res> {
  _$LetterGenerateLoadRequestedCopyWithImpl(this._self, this._then);

  final LetterGenerateLoadRequested _self;
  final $Res Function(LetterGenerateLoadRequested) _then;

/// Create a copy of LetterGenerateEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? disputeId = null,}) {
  return _then(LetterGenerateLoadRequested(
null == disputeId ? _self.disputeId : disputeId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LetterGenerateTemplateChanged implements LetterGenerateEvent {
  const LetterGenerateTemplateChanged(this.templateId);
  

 final  String templateId;

/// Create a copy of LetterGenerateEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LetterGenerateTemplateChangedCopyWith<LetterGenerateTemplateChanged> get copyWith => _$LetterGenerateTemplateChangedCopyWithImpl<LetterGenerateTemplateChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterGenerateTemplateChanged&&(identical(other.templateId, templateId) || other.templateId == templateId));
}


@override
int get hashCode => Object.hash(runtimeType,templateId);

@override
String toString() {
  return 'LetterGenerateEvent.templateChanged(templateId: $templateId)';
}


}

/// @nodoc
abstract mixin class $LetterGenerateTemplateChangedCopyWith<$Res> implements $LetterGenerateEventCopyWith<$Res> {
  factory $LetterGenerateTemplateChangedCopyWith(LetterGenerateTemplateChanged value, $Res Function(LetterGenerateTemplateChanged) _then) = _$LetterGenerateTemplateChangedCopyWithImpl;
@useResult
$Res call({
 String templateId
});




}
/// @nodoc
class _$LetterGenerateTemplateChangedCopyWithImpl<$Res>
    implements $LetterGenerateTemplateChangedCopyWith<$Res> {
  _$LetterGenerateTemplateChangedCopyWithImpl(this._self, this._then);

  final LetterGenerateTemplateChanged _self;
  final $Res Function(LetterGenerateTemplateChanged) _then;

/// Create a copy of LetterGenerateEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? templateId = null,}) {
  return _then(LetterGenerateTemplateChanged(
null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LetterGenerateMailTypeChanged implements LetterGenerateEvent {
  const LetterGenerateMailTypeChanged(this.mailType);
  

 final  String mailType;

/// Create a copy of LetterGenerateEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LetterGenerateMailTypeChangedCopyWith<LetterGenerateMailTypeChanged> get copyWith => _$LetterGenerateMailTypeChangedCopyWithImpl<LetterGenerateMailTypeChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterGenerateMailTypeChanged&&(identical(other.mailType, mailType) || other.mailType == mailType));
}


@override
int get hashCode => Object.hash(runtimeType,mailType);

@override
String toString() {
  return 'LetterGenerateEvent.mailTypeChanged(mailType: $mailType)';
}


}

/// @nodoc
abstract mixin class $LetterGenerateMailTypeChangedCopyWith<$Res> implements $LetterGenerateEventCopyWith<$Res> {
  factory $LetterGenerateMailTypeChangedCopyWith(LetterGenerateMailTypeChanged value, $Res Function(LetterGenerateMailTypeChanged) _then) = _$LetterGenerateMailTypeChangedCopyWithImpl;
@useResult
$Res call({
 String mailType
});




}
/// @nodoc
class _$LetterGenerateMailTypeChangedCopyWithImpl<$Res>
    implements $LetterGenerateMailTypeChangedCopyWith<$Res> {
  _$LetterGenerateMailTypeChangedCopyWithImpl(this._self, this._then);

  final LetterGenerateMailTypeChanged _self;
  final $Res Function(LetterGenerateMailTypeChanged) _then;

/// Create a copy of LetterGenerateEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? mailType = null,}) {
  return _then(LetterGenerateMailTypeChanged(
null == mailType ? _self.mailType : mailType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LetterGenerateSubmitted implements LetterGenerateEvent {
  const LetterGenerateSubmitted();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterGenerateSubmitted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LetterGenerateEvent.submitted()';
}


}




// dart format on
