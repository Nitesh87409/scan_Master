# Goal Description
The `FloatingActionButton` (Scanner button) in the `HomeScreen` is blinking or re-animating every time the user clicks on a filter or changes a tab (which triggers a `setState`). We need to fix this so the button remains stable.

## Analysis of the Issue
The issue is caused by the `floatingActionButtonLocation` property in the `Scaffold`. 
In `home_screen.dart`, the location is defined as:
```dart
floatingActionButtonLocation: _FixedCenterDockedFabLocation(
  bottomPadding: MediaQuery.of(context).padding.bottom,
),
```
Because `_FixedCenterDockedFabLocation` is instantiated dynamically on every `build()` without a `const` modifier, and because it does not override `operator ==`, Flutter treats every new instance as a *different* location. 
Whenever a `Scaffold` detects that the `floatingActionButtonLocation` reference has changed, it automatically triggers a transition animation to move the FAB to the "new" location. Since this happens on every `setState` (like clicking a filter), it creates an annoying blinking/stuttering effect.

## Proposed Changes

### `lib/features/home/screens/home_screen.dart`
#### [MODIFY] home_screen.dart
I will update the `_FixedCenterDockedFabLocation` class to override `operator ==` and `hashCode`. This will ensure that Flutter recognizes the location as being identical across rebuilds (as long as the `bottomPadding` hasn't changed), preventing the unwanted blinking animation.

```dart
class _FixedCenterDockedFabLocation extends FloatingActionButtonLocation {
  final double bottomPadding;
  const _FixedCenterDockedFabLocation({this.bottomPadding = 0.0});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2.0;
    final double fabY = scaffoldGeometry.scaffoldSize.height - 58.0 - bottomPadding - (scaffoldGeometry.floatingActionButtonSize.height / 2.0) + 15.0; // 58 is bottom app bar height
    return Offset(fabX, fabY);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _FixedCenterDockedFabLocation && other.bottomPadding == bottomPadding;
  }

  @override
  int get hashCode => bottomPadding.hashCode;
}
```

## User Review Required
Please review this implementation plan. Once you give the explicit approval ("proceed", "yes", etc.), I will apply this fix.

## Verification Plan
After applying the fix, the Scanner button should no longer blink or animate unnecessarily when interacting with filters or tabs on the Home screen.
