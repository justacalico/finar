import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart';

/// Controller/Gamepad input actions
enum ControllerAction {
  up,
  down,
  left,
  right,
  select,    // A button / Enter
  back,      // B button / Escape
  menu,      // Start button
  playPause, // Media play/pause
  fastForward,
  rewind,
  shoulder,  // Shoulder buttons (L1/R1)
  trigger,   // Trigger buttons (L2/R2)
}

/// Service for handling gamepad/controller and TV remote input
class ControllerService {
  ControllerService._();
  
  /// Map of logical keys to controller actions
  static final Map<LogicalKeyboardKey, ControllerAction> _keyMap = {
    // D-pad / Arrow keys
    LogicalKeyboardKey.arrowUp: ControllerAction.up,
    LogicalKeyboardKey.arrowDown: ControllerAction.down,
    LogicalKeyboardKey.arrowLeft: ControllerAction.left,
    LogicalKeyboardKey.arrowRight: ControllerAction.right,
    
    // Select/Confirm
    LogicalKeyboardKey.enter: ControllerAction.select,
    LogicalKeyboardKey.numpadEnter: ControllerAction.select,
    LogicalKeyboardKey.space: ControllerAction.select,
    LogicalKeyboardKey.select: ControllerAction.select,
    LogicalKeyboardKey.gameButtonA: ControllerAction.select,
    
    // Back/Cancel
    LogicalKeyboardKey.escape: ControllerAction.back,
    LogicalKeyboardKey.goBack: ControllerAction.back,
    LogicalKeyboardKey.browserBack: ControllerAction.back,
    LogicalKeyboardKey.gameButtonB: ControllerAction.back,
    
    // Menu
    LogicalKeyboardKey.gameButtonStart: ControllerAction.menu,
    LogicalKeyboardKey.contextMenu: ControllerAction.menu,
    
    // Media controls
    LogicalKeyboardKey.mediaPlayPause: ControllerAction.playPause,
    LogicalKeyboardKey.mediaPlay: ControllerAction.playPause,
    LogicalKeyboardKey.mediaPause: ControllerAction.playPause,
    LogicalKeyboardKey.mediaFastForward: ControllerAction.fastForward,
    LogicalKeyboardKey.mediaRewind: ControllerAction.rewind,
    
    // Shoulder buttons
    LogicalKeyboardKey.gameButtonLeft1: ControllerAction.shoulder,
    LogicalKeyboardKey.gameButtonRight1: ControllerAction.shoulder,
    LogicalKeyboardKey.pageUp: ControllerAction.shoulder,
    LogicalKeyboardKey.pageDown: ControllerAction.shoulder,
    
    // Triggers
    LogicalKeyboardKey.gameButtonLeft2: ControllerAction.trigger,
    LogicalKeyboardKey.gameButtonRight2: ControllerAction.trigger,
  };
  
  /// Convert a keyboard event to a controller action
  static ControllerAction? getAction(KeyEvent event) {
    return _keyMap[event.logicalKey];
  }
  
  /// Check if the event is a key down event
  static bool isKeyDown(KeyEvent event) {
    return event is KeyDownEvent;
  }
  
  /// Check if the event is a key up event
  static bool isKeyUp(KeyEvent event) {
    return event is KeyUpEvent;
  }
  
  /// Check if the event is a navigation key (directional)
  static bool isNavigationKey(KeyEvent event) {
    final action = getAction(event);
    return action == ControllerAction.up ||
           action == ControllerAction.down ||
           action == ControllerAction.left ||
           action == ControllerAction.right;
  }
  
  /// Get the traversal direction for focus navigation
  static TraversalDirection? getTraversalDirection(KeyEvent event) {
    final action = getAction(event);
    switch (action) {
      case ControllerAction.up:
        return TraversalDirection.up;
      case ControllerAction.down:
        return TraversalDirection.down;
      case ControllerAction.left:
        return TraversalDirection.left;
      case ControllerAction.right:
        return TraversalDirection.right;
      default:
        return null;
    }
  }
}

/// Gamepad state for connected controllers
class GamepadState {
  final List<GamepadController> connectedGamepads;
  final bool isGamepadConnected;
  final String? lastInput;

  const GamepadState({
    this.connectedGamepads = const [],
    this.isGamepadConnected = false,
    this.lastInput,
  });

  GamepadState copyWith({
    List<GamepadController>? connectedGamepads,
    bool? isGamepadConnected,
    String? lastInput,
  }) {
    return GamepadState(
      connectedGamepads: connectedGamepads ?? this.connectedGamepads,
      isGamepadConnected: isGamepadConnected ?? this.isGamepadConnected,
      lastInput: lastInput ?? this.lastInput,
    );
  }
}

/// Provider for gamepad state
final gamepadStateProvider = StateNotifierProvider<GamepadNotifier, GamepadState>((ref) {
  return GamepadNotifier();
});

/// Notifier for managing gamepad connections and input
class GamepadNotifier extends StateNotifier<GamepadState> {
  StreamSubscription<GamepadEvent>? _eventSubscription;
  final _actionController = StreamController<ControllerAction>.broadcast();
  
  /// Stream of controller actions from gamepad
  Stream<ControllerAction> get actionStream => _actionController.stream;
  
  // Axis state tracking for analog-to-digital conversion
  final Map<String, Map<int, double>> _axisStates = {};
  static const double _axisThreshold = 0.5;
  final Map<String, Map<int, bool>> _axisTriggered = {};

  GamepadNotifier() : super(const GamepadState()) {
    _initGamepads();
    // Periodically refresh gamepad list for hot-plugged controllers
    _startPeriodicRefresh();
  }
  
  Timer? _refreshTimer;
  
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      refreshGamepads();
    });
  }

  Future<void> _initGamepads() async {
    try {
      // Listen for gamepad events
      _eventSubscription = Gamepads.events.listen(_handleGamepadEvent);
      
      // Get initially connected gamepads
      final gamepads = await Gamepads.list();
      state = state.copyWith(
        connectedGamepads: gamepads,
        isGamepadConnected: gamepads.isNotEmpty,
      );
      
      if (kDebugMode) {
        debugPrint('GamepadNotifier: Initialized with ${gamepads.length} gamepad(s)');
        for (final gp in gamepads) {
          debugPrint('  - ${gp.name} (ID: ${gp.id})');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('GamepadNotifier: Failed to initialize gamepads: $e');
      }
    }
  }

  void _handleGamepadEvent(GamepadEvent event) {
    final gamepadId = event.gamepadId;
    
    // Initialize tracking maps for this gamepad if needed
    _axisStates.putIfAbsent(gamepadId, () => {});
    _axisTriggered.putIfAbsent(gamepadId, () => {});
    
    // GamepadEvent has type (KeyType.button or KeyType.analog), key, and value
    if (event.type == KeyType.button) {
      _handleButtonEvent(event);
    } else if (event.type == KeyType.analog) {
      _handleAnalogEvent(gamepadId, event);
    }
    
    state = state.copyWith(lastInput: '${event.key}: ${event.value}');
  }

  void _handleButtonEvent(GamepadEvent event) {
    // Button events from gamepads package
    final key = event.key.toLowerCase();
    
    if (kDebugMode) {
      debugPrint('GamepadNotifier: Button event - key: $key, value: ${event.value}');
    }
    
    // Only handle button press (value == 1.0), not release (value == 0.0)
    if (event.value != 1.0) return;
    
    ControllerAction? action;
    
    // Map common button names to actions
    // Xbox: a, b, x, y, lb, rb, lt, rt, start, back, dpup, dpdown, dpleft, dpright
    // PlayStation: cross, circle, square, triangle, l1, r1, l2, r2, options, share
    // Steam Deck: button_south, button_east, button_north, button_west, etc.
    // SDL names: a, b, x, y, leftshoulder, rightshoulder, etc.
    switch (key) {
      // D-pad - standard names
      case 'dpup':
      case 'dpad_up':
      case 'dpadup':
      case 'hat0_up':
      case 'hat_up':
        action = ControllerAction.up;
        break;
      case 'dpdown':
      case 'dpad_down':
      case 'dpaddown':
      case 'hat0_down':
      case 'hat_down':
        action = ControllerAction.down;
        break;
      case 'dpleft':
      case 'dpad_left':
      case 'dpadleft':
      case 'hat0_left':
      case 'hat_left':
        action = ControllerAction.left;
        break;
      case 'dpright':
      case 'dpad_right':
      case 'dpadright':
      case 'hat0_right':
      case 'hat_right':
        action = ControllerAction.right;
        break;
        
      // Face buttons - Select/Confirm (A on Xbox / Cross on PS / South button)
      case 'a':
      case 'cross':
      case 'button_a':
      case 'button_south':
      case 'btn_south':
      case 'south':
      case 'button_0':
      case 'btn_a':
        action = ControllerAction.select;
        break;
        
      // Face buttons - Back/Cancel (B on Xbox / Circle on PS / East button)
      case 'b':
      case 'circle':
      case 'button_b':
      case 'button_east':
      case 'btn_east':
      case 'east':
      case 'button_1':
      case 'btn_b':
        action = ControllerAction.back;
        break;
        
      // Menu buttons
      case 'start':
      case 'options':
      case 'menu':
      case 'button_start':
      case 'btn_start':
      case 'button_9':
      case 'plus':
        action = ControllerAction.menu;
        break;
      
      // Back/Select button (can also be used for back navigation)
      case 'back':
      case 'select':
      case 'share':
      case 'button_select':
      case 'btn_select':
      case 'button_8':
      case 'minus':
        action = ControllerAction.back;
        break;
        
      // Shoulder buttons (L1/R1, LB/RB)
      case 'lb':
      case 'rb':
      case 'l1':
      case 'r1':
      case 'left_shoulder':
      case 'right_shoulder':
      case 'leftshoulder':
      case 'rightshoulder':
      case 'button_l1':
      case 'button_r1':
      case 'btn_tl':
      case 'btn_tr':
      case 'button_4':
      case 'button_5':
        action = ControllerAction.shoulder;
        break;
        
      // Triggers (L2/R2, LT/RT)
      case 'lt':
      case 'rt':
      case 'l2':
      case 'r2':
      case 'left_trigger':
      case 'right_trigger':
      case 'lefttrigger':
      case 'righttrigger':
      case 'button_l2':
      case 'button_r2':
      case 'btn_tl2':
      case 'btn_tr2':
      case 'button_6':
      case 'button_7':
        action = ControllerAction.trigger;
        break;
      
      // X/Y buttons (for potential future use)
      case 'x':
      case 'square':
      case 'button_x':
      case 'button_west':
      case 'btn_west':
      case 'west':
      case 'button_2':
      case 'btn_x':
        // Could map to a specific action if needed
        break;
      case 'y':
      case 'triangle':
      case 'button_y':
      case 'button_north':
      case 'btn_north':
      case 'north':
      case 'button_3':
      case 'btn_y':
        // Could map to a specific action if needed
        break;
    }
    
    if (action != null) {
      _actionController.add(action);
    }
  }

  void _handleAnalogEvent(String gamepadId, GamepadEvent event) {
    final axisKey = event.key.toLowerCase();
    final axisIndex = axisKey.hashCode;
    final value = event.value;
    
    if (kDebugMode) {
      debugPrint('GamepadNotifier: Analog event - key: $axisKey, value: $value');
    }
    
    // Store the current axis value
    _axisStates[gamepadId]![axisIndex] = value;
    
    // Convert analog input to digital actions (with threshold)
    // This handles left stick navigation
    final wasTriggered = _axisTriggered[gamepadId]![axisIndex] ?? false;
    
    ControllerAction? action;
    bool shouldTrigger = false;
    
    // Left stick X axis (left/right)
    // SDL: leftx, Linux evdev: abs_x, axis_0, axis_lx
    // Steam Deck: may use abs_x, leftx, or numbered axis
    final isLeftXAxis = axisKey.contains('leftx') || 
                        axisKey.contains('left_x') || 
                        axisKey == 'axis_0' ||
                        axisKey == 'abs_x' ||
                        axisKey == 'axis_lx' ||
                        axisKey == 'x';
    
    // Left stick Y axis (up/down)
    // SDL: lefty, Linux evdev: abs_y, axis_1, axis_ly
    final isLeftYAxis = axisKey.contains('lefty') || 
                        axisKey.contains('left_y') || 
                        axisKey == 'axis_1' ||
                        axisKey == 'abs_y' ||
                        axisKey == 'axis_ly' ||
                        axisKey == 'y';
    
    // D-pad as axis (some controllers send D-pad as hat/axis)
    // Steam Deck may send D-pad as abs_hat0x/abs_hat0y
    final isDpadXAxis = axisKey.contains('hat0x') || 
                        axisKey.contains('hat_x') ||
                        axisKey == 'abs_hat0x' ||
                        axisKey == 'dpad_x';
    
    final isDpadYAxis = axisKey.contains('hat0y') || 
                        axisKey.contains('hat_y') ||
                        axisKey == 'abs_hat0y' ||
                        axisKey == 'dpad_y';
    
    if (isLeftXAxis || isDpadXAxis) {
      if (value < -_axisThreshold && !wasTriggered) {
        action = ControllerAction.left;
        shouldTrigger = true;
      } else if (value > _axisThreshold && !wasTriggered) {
        action = ControllerAction.right;
        shouldTrigger = true;
      } else if (value.abs() < _axisThreshold * 0.5) {
        // Reset when back to center
        _axisTriggered[gamepadId]![axisIndex] = false;
      }
    } else if (isLeftYAxis || isDpadYAxis) {
      // Note: Y axis is typically inverted (negative = up, positive = down)
      // But some controllers may have it non-inverted
      if (value < -_axisThreshold && !wasTriggered) {
        action = ControllerAction.up;
        shouldTrigger = true;
      } else if (value > _axisThreshold && !wasTriggered) {
        action = ControllerAction.down;
        shouldTrigger = true;
      } else if (value.abs() < _axisThreshold * 0.5) {
        _axisTriggered[gamepadId]![axisIndex] = false;
      }
    }
    
    if (shouldTrigger) {
      _axisTriggered[gamepadId]![axisIndex] = true;
      if (action != null) {
        _actionController.add(action);
      }
    }
  }

  /// Refresh the list of connected gamepads
  Future<void> refreshGamepads() async {
    try {
      final gamepads = await Gamepads.list();
      state = state.copyWith(
        connectedGamepads: gamepads,
        isGamepadConnected: gamepads.isNotEmpty,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('GamepadNotifier: Failed to refresh gamepads: $e');
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _eventSubscription?.cancel();
    _actionController.close();
    super.dispose();
  }
}

/// Provider for controller input state
final controllerEnabledProvider = StateProvider<bool>((ref) => true);

/// Mixin for widgets that need controller/focus support
mixin ControllerNavigationMixin<T extends StatefulWidget> on State<T> {
  late FocusNode _controllerFocusNode;
  bool _isFocused = false;
  
  FocusNode get controllerFocusNode => _controllerFocusNode;
  bool get isFocused => _isFocused;
  
  @override
  void initState() {
    super.initState();
    _controllerFocusNode = FocusNode(debugLabel: widget.runtimeType.toString());
    _controllerFocusNode.addListener(_onFocusChange);
  }
  
  @override
  void dispose() {
    _controllerFocusNode.removeListener(_onFocusChange);
    _controllerFocusNode.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _controllerFocusNode.hasFocus;
      });
      onFocusChanged(_isFocused);
    }
  }
  
  /// Override to handle focus changes
  void onFocusChanged(bool hasFocus) {}
  
  /// Handle key events for controller navigation
  KeyEventResult handleControllerInput(KeyEvent event) {
    if (!ControllerService.isKeyDown(event)) {
      return KeyEventResult.ignored;
    }
    
    final action = ControllerService.getAction(event);
    if (action == null) return KeyEventResult.ignored;
    
    switch (action) {
      case ControllerAction.select:
        onControllerSelect();
        return KeyEventResult.handled;
      case ControllerAction.back:
        if (onControllerBack()) {
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      case ControllerAction.menu:
        onControllerMenu();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }
  
  /// Override to handle select action (A button / Enter)
  void onControllerSelect() {}
  
  /// Override to handle back action (B button / Escape)
  /// Return true if handled, false to propagate
  bool onControllerBack() => false;
  
  /// Override to handle menu action (Start button)
  void onControllerMenu() {}
}

/// A focusable widget wrapper for controller/remote navigation
class FocusableItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final VoidCallback? onFocus;
  final VoidCallback? onUnfocus;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool enabled;
  final BoxDecoration? focusDecoration;
  final Duration animationDuration;
  
  const FocusableItem({
    super.key,
    required this.child,
    this.onSelect,
    this.onFocus,
    this.onUnfocus,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.focusDecoration,
    this.animationDuration = const Duration(milliseconds: 150),
  });
  
  @override
  State<FocusableItem> createState() => _FocusableItemState();
}

class _FocusableItemState extends State<FocusableItem> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  
  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }
  
  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }
  
  void _handleFocusChange() {
    if (mounted) {
      final hadFocus = _isFocused;
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      
      if (_isFocused && !hadFocus) {
        widget.onFocus?.call();
      } else if (!_isFocused && hadFocus) {
        widget.onUnfocus?.call();
      }
    }
  }
  
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled || !ControllerService.isKeyDown(event)) {
      return KeyEventResult.ignored;
    }
    
    final action = ControllerService.getAction(event);
    if (action == ControllerAction.select) {
      widget.onSelect?.call();
      return KeyEventResult.handled;
    }
    
    return KeyEventResult.ignored;
  }
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onSelect,
        child: AnimatedContainer(
          duration: widget.animationDuration,
          decoration: _isFocused ? widget.focusDecoration : null,
          child: AnimatedScale(
            scale: _isFocused ? 1.02 : 1.0,
            duration: widget.animationDuration,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Focus-aware scroll controller that ensures focused items are visible
class FocusAwareScrollController {
  final ScrollController scrollController;
  final double scrollPadding;
  
  FocusAwareScrollController({
    ScrollController? controller,
    this.scrollPadding = 100.0,
  }) : scrollController = controller ?? ScrollController();
  
  void dispose() {
    scrollController.dispose();
  }
  
  /// Ensure a specific offset is visible
  void ensureVisible(double offset, double itemHeight) {
    if (!scrollController.hasClients) return;
    
    final viewportStart = scrollController.offset;
    final viewportEnd = viewportStart + scrollController.position.viewportDimension;
    
    if (offset < viewportStart + scrollPadding) {
      scrollController.animateTo(
        (offset - scrollPadding).clamp(0.0, scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    } else if (offset + itemHeight > viewportEnd - scrollPadding) {
      scrollController.animateTo(
        (offset + itemHeight + scrollPadding - scrollController.position.viewportDimension)
            .clamp(0.0, scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }
}

/// A row of focusable items with automatic scroll-into-view
class FocusableRow extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final double itemSpacing;
  final EdgeInsets padding;
  final ScrollController? scrollController;
  
  const FocusableRow({
    super.key,
    required this.children,
    this.height = 200,
    this.itemSpacing = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.scrollController,
  });
  
  @override
  State<FocusableRow> createState() => _FocusableRowState();
}

class _FocusableRowState extends State<FocusableRow> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }
  
  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        itemCount: widget.children.length,
        separatorBuilder: (_, _) => SizedBox(width: widget.itemSpacing),
        itemBuilder: (context, index) {
          return _FocusableRowItem(
            scrollController: _scrollController,
            itemIndex: index,
            child: widget.children[index],
          );
        },
      ),
    );
  }
}

class _FocusableRowItem extends StatelessWidget {
  final ScrollController scrollController;
  final int itemIndex;
  final Widget child;
  
  const _FocusableRowItem({
    required this.scrollController,
    required this.itemIndex,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return NotificationListener<FocusedNotification>(
      onNotification: (notification) {
        _ensureVisible(context);
        return true;
      },
      child: Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            _ensureVisible(context);
          }
        },
        child: child,
      ),
    );
  }
  
  void _ensureVisible(BuildContext context) {
    if (!scrollController.hasClients) return;
    
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final position = renderBox.localToGlobal(Offset.zero);
    final scrollPosition = scrollController.position;
    
    // Get item's position relative to scroll view
    final itemStart = position.dx;
    final itemEnd = itemStart + renderBox.size.width;
    
    if (itemStart < 100) {
      scrollController.animateTo(
        (scrollPosition.pixels + itemStart - 100).clamp(0.0, scrollPosition.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    } else if (itemEnd > scrollPosition.viewportDimension - 100) {
      scrollController.animateTo(
        (scrollPosition.pixels + (itemEnd - scrollPosition.viewportDimension + 100))
            .clamp(0.0, scrollPosition.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }
}

/// Notification sent when an item receives focus
class FocusedNotification extends Notification {
  final int index;
  FocusedNotification(this.index);
}

/// A widget that handles directional focus traversal for grids
class FocusTraversalGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets padding;
  
  const FocusTraversalGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 4,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 2 / 3,
    this.padding = const EdgeInsets.all(16),
  });
  
  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: GridView.builder(
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) {
          return FocusTraversalOrder(
            order: NumericFocusOrder(index.toDouble()),
            child: children[index],
          );
        },
      ),
    );
  }
}
