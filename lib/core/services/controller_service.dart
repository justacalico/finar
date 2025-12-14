import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    
    // Calculate if item is outside viewport
    final viewportStart = scrollPosition.pixels;
    final viewportEnd = viewportStart + scrollPosition.viewportDimension;
    
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
