import 'package:flutter/material.dart';

/// Breakpoints for responsive design
class Breakpoints {
  Breakpoints._();

  /// Mobile breakpoint (0-599px)
  static const double mobile = 600;

  /// Tablet breakpoint (600-1023px)
  static const double tablet = 1024;

  /// Desktop breakpoint (1024-1439px)
  static const double desktop = 1440;

  /// Large desktop breakpoint (1440px+)
  static const double largeDesktop = 1440;
}

/// Device type enumeration
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// Extension on BuildContext for responsive utilities
extension ResponsiveExtension on BuildContext {
  /// Get the current screen width
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Get the current screen height
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Check if the current device is mobile
  bool get isMobile => screenWidth < Breakpoints.mobile;

  /// Check if the current device is tablet
  bool get isTablet =>
      screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.tablet;

  /// Check if the current device is desktop
  bool get isDesktop =>
      screenWidth >= Breakpoints.tablet && screenWidth < Breakpoints.desktop;

  /// Check if the current device is large desktop
  bool get isLargeDesktop => screenWidth >= Breakpoints.largeDesktop;

  /// Check if the current device is mobile or tablet
  bool get isMobileOrTablet => screenWidth < Breakpoints.tablet;

  /// Check if the current device is tablet or larger
  bool get isTabletOrLarger => screenWidth >= Breakpoints.mobile;

  /// Check if the current device is desktop or larger
  bool get isDesktopOrLarger => screenWidth >= Breakpoints.tablet;

  /// Get the current device type
  DeviceType get deviceType {
    if (isMobile) return DeviceType.mobile;
    if (isTablet) return DeviceType.tablet;
    if (isDesktop) return DeviceType.desktop;
    return DeviceType.largeDesktop;
  }

  /// Get responsive padding based on screen size
  EdgeInsets get responsivePadding {
    if (isMobile) return const EdgeInsets.all(16);
    if (isTablet) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  /// Get responsive horizontal padding
  double get responsiveHorizontalPadding {
    if (isMobile) return 16;
    if (isTablet) return 24;
    return 32;
  }

  /// Get the number of grid columns based on screen size
  int get gridColumns {
    if (isMobile) return 1;
    if (isTablet) return 2;
    if (isDesktop) return 3;
    return 4;
  }
}

/// A responsive builder widget that builds different layouts based on screen size.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.largeDesktop) {
          return largeDesktop ?? desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= Breakpoints.tablet) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= Breakpoints.mobile) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// A responsive visibility widget that shows/hides content based on screen size.
class ResponsiveVisibility extends StatelessWidget {
  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleOnMobile = true,
    this.visibleOnTablet = true,
    this.visibleOnDesktop = true,
    this.visibleOnLargeDesktop = true,
    this.replacement,
  });

  final Widget child;
  final bool visibleOnMobile;
  final bool visibleOnTablet;
  final bool visibleOnDesktop;
  final bool visibleOnLargeDesktop;
  final Widget? replacement;

  @override
  Widget build(BuildContext context) {
    final deviceType = context.deviceType;

    final isVisible = switch (deviceType) {
      DeviceType.mobile => visibleOnMobile,
      DeviceType.tablet => visibleOnTablet,
      DeviceType.desktop => visibleOnDesktop,
      DeviceType.largeDesktop => visibleOnLargeDesktop,
    };

    if (isVisible) {
      return child;
    }

    return replacement ?? const SizedBox.shrink();
  }
}

/// A responsive grid that adjusts columns based on screen size.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.largeDesktopColumns = 4,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio = 1.0,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int largeDesktopColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final columns = switch (context.deviceType) {
      DeviceType.mobile => mobileColumns,
      DeviceType.tablet => tabletColumns,
      DeviceType.desktop => desktopColumns,
      DeviceType.largeDesktop => largeDesktopColumns,
    };

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// A responsive row that wraps to column on smaller screens.
class ResponsiveRowColumn extends StatelessWidget {
  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.rowMainAxisAlignment = MainAxisAlignment.start,
    this.rowCrossAxisAlignment = CrossAxisAlignment.center,
    this.columnMainAxisAlignment = MainAxisAlignment.start,
    this.columnCrossAxisAlignment = CrossAxisAlignment.start,
    this.rowSpacing = 16,
    this.columnSpacing = 16,
    this.breakpoint = Breakpoints.mobile,
  });

  final List<Widget> children;
  final MainAxisAlignment rowMainAxisAlignment;
  final CrossAxisAlignment rowCrossAxisAlignment;
  final MainAxisAlignment columnMainAxisAlignment;
  final CrossAxisAlignment columnCrossAxisAlignment;
  final double rowSpacing;
  final double columnSpacing;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            mainAxisAlignment: columnMainAxisAlignment,
            crossAxisAlignment: columnCrossAxisAlignment,
            mainAxisSize: MainAxisSize.min,
            children: _buildChildrenWithSpacing(columnSpacing, Axis.vertical),
          );
        }

        return Row(
          mainAxisAlignment: rowMainAxisAlignment,
          crossAxisAlignment: rowCrossAxisAlignment,
          children: _buildChildrenWithSpacing(rowSpacing, Axis.horizontal),
        );
      },
    );
  }

  List<Widget> _buildChildrenWithSpacing(double spacing, Axis axis) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(axis == Axis.horizontal
            ? SizedBox(width: spacing)
            : SizedBox(height: spacing));
      }
    }
    return result;
  }
}

/// A responsive container that constrains max width on larger screens.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding ?? context.responsivePadding,
        child: child,
      ),
    );
  }
}

/// A responsive data table that shows as cards on mobile.
class ResponsiveDataDisplay<T> extends StatelessWidget {
  const ResponsiveDataDisplay({
    super.key,
    required this.items,
    required this.tableBuilder,
    required this.cardBuilder,
    this.breakpoint = Breakpoints.tablet,
  });

  final List<T> items;
  final Widget Function(List<T> items) tableBuilder;
  final Widget Function(T item) cardBuilder;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => cardBuilder(items[index]),
          );
        }

        return tableBuilder(items);
      },
    );
  }
}

/// A responsive text that scales based on screen size.
class ResponsiveText extends StatelessWidget {
  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.mobileScale = 0.85,
    this.tabletScale = 0.95,
    this.desktopScale = 1.0,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final double mobileScale;
  final double tabletScale;
  final double desktopScale;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final scale = switch (context.deviceType) {
      DeviceType.mobile => mobileScale,
      DeviceType.tablet => tabletScale,
      DeviceType.desktop || DeviceType.largeDesktop => desktopScale,
    };

    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    final scaledStyle = baseStyle?.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * scale,
    );

    return Text(
      text,
      style: scaledStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
