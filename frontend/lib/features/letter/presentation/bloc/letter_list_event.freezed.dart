// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'letter_list_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LetterListEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterListEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LetterListEvent()';
}


}

/// @nodoc
class $LetterListEventCopyWith<$Res>  {
$LetterListEventCopyWith(LetterListEvent _, $Res Function(LetterListEvent) __);
}


/// Adds pattern-matching-related methods to [LetterListEvent].
extension LetterListEventPatterns on LetterListEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LetterListLoadRequested value)?  loadRequested,TResult Function( LetterListRefreshRequested value)?  refreshRequested,TResult Function( LetterListLoadMoreRequested value)?  loadMoreRequested,TResult Function( LetterListStatusFilterChanged value)?  statusFilterChanged,TResult Function( LetterListSearchChanged value)?  searchChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LetterListLoadRequested() when loadRequested != null:
return loadRequested(_that);case LetterListRefreshRequested() when refreshRequested != null:
return refreshRequested(_that);case LetterListLoadMoreRequested() when loadMoreRequested != null:
return loadMoreRequested(_that);case LetterListStatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that);case LetterListSearchChanged() when searchChanged != null:
return searchChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LetterListLoadRequested value)  loadRequested,required TResult Function( LetterListRefreshRequested value)  refreshRequested,required TResult Function( LetterListLoadMoreRequested value)  loadMoreRequested,required TResult Function( LetterListStatusFilterChanged value)  statusFilterChanged,required TResult Function( LetterListSearchChanged value)  searchChanged,}){
final _that = this;
switch (_that) {
case LetterListLoadRequested():
return loadRequested(_that);case LetterListRefreshRequested():
return refreshRequested(_that);case LetterListLoadMoreRequested():
return loadMoreRequested(_that);case LetterListStatusFilterChanged():
return statusFilterChanged(_that);case LetterListSearchChanged():
return searchChanged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LetterListLoadRequested value)?  loadRequested,TResult? Function( LetterListRefreshRequested value)?  refreshRequested,TResult? Function( LetterListLoadMoreRequested value)?  loadMoreRequested,TResult? Function( LetterListStatusFilterChanged value)?  statusFilterChanged,TResult? Function( LetterListSearchChanged value)?  searchChanged,}){
final _that = this;
switch (_that) {
case LetterListLoadRequested() when loadRequested != null:
return loadRequested(_that);case LetterListRefreshRequested() when refreshRequested != null:
return refreshRequested(_that);case LetterListLoadMoreRequested() when loadMoreRequested != null:
return loadMoreRequested(_that);case LetterListStatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that);case LetterListSearchChanged() when searchChanged != null:
return searchChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadRequested,TResult Function()?  refreshRequested,TResult Function()?  loadMoreRequested,TResult Function( String? status)?  statusFilterChanged,TResult Function( String query)?  searchChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LetterListLoadRequested() when loadRequested != null:
return loadRequested();case LetterListRefreshRequested() when refreshRequested != null:
return refreshRequested();case LetterListLoadMoreRequested() when loadMoreRequested != null:
return loadMoreRequested();case LetterListStatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that.status);case LetterListSearchChanged() when searchChanged != null:
return searchChanged(_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadRequested,required TResult Function()  refreshRequested,required TResult Function()  loadMoreRequested,required TResult Function( String? status)  statusFilterChanged,required TResult Function( String query)  searchChanged,}) {final _that = this;
switch (_that) {
case LetterListLoadRequested():
return loadRequested();case LetterListRefreshRequested():
return refreshRequested();case LetterListLoadMoreRequested():
return loadMoreRequested();case LetterListStatusFilterChanged():
return statusFilterChanged(_that.status);case LetterListSearchChanged():
return searchChanged(_that.query);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadRequested,TResult? Function()?  refreshRequested,TResult? Function()?  loadMoreRequested,TResult? Function( String? status)?  statusFilterChanged,TResult? Function( String query)?  searchChanged,}) {final _that = this;
switch (_that) {
case LetterListLoadRequested() when loadRequested != null:
return loadRequested();case LetterListRefreshRequested() when refreshRequested != null:
return refreshRequested();case LetterListLoadMoreRequested() when loadMoreRequested != null:
return loadMoreRequested();case LetterListStatusFilterChanged() when statusFilterChanged != null:
return statusFilterChanged(_that.status);case LetterListSearchChanged() when searchChanged != null:
return searchChanged(_that.query);case _:
  return null;

}
}

}

/// @nodoc


class LetterListLoadRequested implements LetterListEvent {
  const LetterListLoadRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterListLoadRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LetterListEvent.loadRequested()';
}


}




/// @nodoc


class LetterListRefreshRequested implements LetterListEvent {
  const LetterListRefreshRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterListRefreshRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LetterListEvent.refreshRequested()';
}


}




/// @nodoc


class LetterListLoadMoreRequested implements LetterListEvent {
  const LetterListLoadMoreRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterListLoadMoreRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LetterListEvent.loadMoreRequested()';
}


}




/// @nodoc


class LetterListStatusFilterChanged implements LetterListEvent {
  const LetterListStatusFilterChanged(this.status);
  

 final  String? status;

/// Create a copy of LetterListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LetterListStatusFilterChangedCopyWith<LetterListStatusFilterChanged> get copyWith => _$LetterListStatusFilterChangedCopyWithImpl<LetterListStatusFilterChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterListStatusFilterChanged&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,status);

@override
String toString() {
  return 'LetterListEvent.statusFilterChanged(status: $status)';
}


}

/// @nodoc
abstract mixin class $LetterListStatusFilterChangedCopyWith<$Res> implements $LetterListEventCopyWith<$Res> {
  factory $LetterListStatusFilterChangedCopyWith(LetterListStatusFilterChanged value, $Res Function(LetterListStatusFilterChanged) _then) = _$LetterListStatusFilterChangedCopyWithImpl;
@useResult
$Res call({
 String? status
});




}
/// @nodoc
class _$LetterListStatusFilterChangedCopyWithImpl<$Res>
    implements $LetterListStatusFilterChangedCopyWith<$Res> {
  _$LetterListStatusFilterChangedCopyWithImpl(this._self, this._then);

  final LetterListStatusFilterChanged _self;
  final $Res Function(LetterListStatusFilterChanged) _then;

/// Create a copy of LetterListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = freezed,}) {
  return _then(LetterListStatusFilterChanged(
freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class LetterListSearchChanged implements LetterListEvent {
  const LetterListSearchChanged(this.query);
  

 final  String query;

/// Create a copy of LetterListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LetterListSearchChangedCopyWith<LetterListSearchChanged> get copyWith => _$LetterListSearchChangedCopyWithImpl<LetterListSearchChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LetterListSearchChanged&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'LetterListEvent.searchChanged(query: $query)';
}


}

/// @nodoc
abstract mixin class $LetterListSearchChangedCopyWith<$Res> implements $LetterListEventCopyWith<$Res> {
  factory $LetterListSearchChangedCopyWith(LetterListSearchChanged value, $Res Function(LetterListSearchChanged) _then) = _$LetterListSearchChangedCopyWithImpl;
@useResult
$Res call({
 String query
});




}
/// @nodoc
class _$LetterListSearchChangedCopyWithImpl<$Res>
    implements $LetterListSearchChangedCopyWith<$Res> {
  _$LetterListSearchChangedCopyWithImpl(this._self, this._then);

  final LetterListSearchChanged _self;
  final $Res Function(LetterListSearchChanged) _then;

/// Create a copy of LetterListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(LetterListSearchChanged(
null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
