import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(const SpartanPathApp());

/// ---------------------------------------------------------------------------
///  APP
/// ---------------------------------------------------------------------------
class SpartanPathApp extends StatelessWidget {
  const SpartanPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade100),
        useMaterial3: true,
      ),
      home: const Scaffold(body: SpartanPathSheetDemo()),
    );
  }
}

/// ---------------------------------------------------------------------------
///  SCREEN
/// ---------------------------------------------------------------------------
class SpartanPathSheetDemo extends StatefulWidget {
  const SpartanPathSheetDemo({super.key});

  @override
  State<SpartanPathSheetDemo> createState() => _SpartanPathSheetDemoState();
}

class _SpartanPathSheetDemoState extends State<SpartanPathSheetDemo> {
  int _selectedTab = 0; // 0=Search, 1=Favorites, 2=Me
  final _searchCtrl = TextEditingController();
  String _query = '';

  late final Map<int, List<Location>> _dataByTab = {
    0: searchLocations,
    1: favoriteLocations,
    2: List.generate(
      8,
      (i) => Location(
        name: 'Profile Item $i',
        description: 'Information related to your profile.',
        category: 'Me',
      ),
    ),
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectTab(int tabIndex) {
    setState(() {
      _selectedTab = tabIndex;

      // Optional: clear query when leaving Search tab
      if (tabIndex != _TabIndex.search) {
        _query = '';
        _searchCtrl.clear();
      }
    });
  }

  List<Location> _filteredItems() {
    final items = _dataByTab[_selectedTab] ?? const <Location>[];
    final q = _query.trim();
    if (q.isEmpty) return items;
    return items.where((loc) => loc.matchesQuery(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showSearch = _selectedTab == _TabIndex.search;

    final metrics = _SheetLayoutMetrics.from(context: context, showSearch: showSearch);
    final filtered = _filteredItems();

    return Stack(
      children: [
        _Background(scheme: scheme),

        DraggableScrollableSheet(
          minChildSize: _SheetConfig.minChildSize,
          initialChildSize: _SheetConfig.initialChildSize,
          maxChildSize: _SheetConfig.maxChildSize,
          snap: true,
          snapSizes: _SheetConfig.snapSizes,
          builder: (context, scrollController) {
            return _FrostedSheet(
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TopHeaderDelegate(
                      extent: metrics.pinnedHeaderExtent,
                      showSearch: showSearch,
                      selectedTab: _selectedTab,
                      onSelectTab: _selectTab,
                      searchController: _searchCtrl,
                      onQueryChanged: (s) => setState(() => _query = s),
                      metrics: metrics,
                    ),
                  ),

                  const SliverToBoxAdapter(child: Divider(height: 1)),
                  _ResultsList(items: filtered),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
///  BACKGROUND
/// ---------------------------------------------------------------------------
class _Background extends StatelessWidget {
  const _Background({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        'Background Content',
        style: Theme.of(context)
            .textTheme
            .headlineMedium
            ?.copyWith(color: scheme.onPrimaryContainer),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  SHEET WRAPPER (rounded + blur + translucent)
/// ---------------------------------------------------------------------------
class _FrostedSheet extends StatelessWidget {
  const _FrostedSheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.white.withValues(alpha: 0.85),
          child: child,
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  RESULTS
/// ---------------------------------------------------------------------------
class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.items});
  final List<Location> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No results'),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _LocationTile(location: items[i]),
        childCount: items.length,
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.location});
  final Location location;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(location.name, style: _TextStyles.title),
      subtitle: Text(location.description, style: _TextStyles.subtitle),
    );
  }
}

/// ---------------------------------------------------------------------------
///  HEADER DELEGATE
/// ---------------------------------------------------------------------------
class _TopHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TopHeaderDelegate({
    required this.extent,
    required this.showSearch,
    required this.selectedTab,
    required this.onSelectTab,
    required this.searchController,
    required this.onQueryChanged,
    required this.metrics,
  });

  final double extent;
  final bool showSearch;

  final int selectedTab;
  final ValueChanged<int> onSelectTab;

  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;

  final _SheetLayoutMetrics metrics;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: _Colors.headerNavy,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _Spacing.hPad,
          vertical: metrics.vPad,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Grabber(height: metrics.grabberHeight),
            SizedBox(height: metrics.gap),

            SizedBox(
              height: metrics.tabsHeight,
              child: _TabsRow(
                selectedTab: selectedTab,
                onSelectTab: onSelectTab,
              ),
            ),

            if (showSearch) ...[
              SizedBox(height: metrics.gap),
              SizedBox(
                height: metrics.searchHeight,
                child: _SearchField(
                  controller: searchController,
                  onChanged: onQueryChanged,
                  onClear: () {
                    searchController.clear();
                    onQueryChanged('');
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TopHeaderDelegate old) {
    // Simple + readable: rebuild when any inputs change
    return extent != old.extent ||
        showSearch != old.showSearch ||
        selectedTab != old.selectedTab ||
        searchController != old.searchController ||
        metrics != old.metrics;
  }
}

/// ---------------------------------------------------------------------------
///  HEADER PIECES
/// ---------------------------------------------------------------------------
class _Grabber extends StatelessWidget {
  const _Grabber({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: _Colors.handleWhite,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _TabsRow extends StatelessWidget {
  const _TabsRow({required this.selectedTab, required this.onSelectTab});
  final int selectedTab;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        // kept as const list, actual selected state handled below via builder:
      ],
    )._withChildren([
      _TabIconButton(
        icon: Icons.search,
        label: 'Search',
        selected: selectedTab == _TabIndex.search,
        onTap: () => onSelectTab(_TabIndex.search),
      ),
      _TabIconButton(
        icon: Icons.star,
        label: 'Favorites',
        selected: selectedTab == _TabIndex.favorites,
        onTap: () => onSelectTab(_TabIndex.favorites),
      ),
      _TabIconButton(
        icon: Icons.person,
        label: 'Me',
        selected: selectedTab == _TabIndex.me,
        onTap: () => onSelectTab(_TabIndex.me),
      ),
    ]);
  }
}

/// Tiny helper to keep `_TabsRow` readable without nesting Row(children: [...])
extension on Row {
  Row _withChildren(List<Widget> children) {
    return Row(mainAxisAlignment: mainAxisAlignment, children: children);
  }
}

class _TabIconButton extends StatelessWidget {
  const _TabIconButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _Colors.tabActive : _Colors.tabInactive;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      cursorColor: _Colors.headerNavy,
      style: const TextStyle(color: Colors.black87),
      onChanged: onChanged,
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        hintText: 'Search...',
        hintStyle: const TextStyle(color: Colors.black45),
        prefixIcon: const Icon(Icons.search, color: Colors.black54),
        suffixIcon: IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.clear, color: Colors.black54),
          tooltip: 'Clear',
        ),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  LAYOUT METRICS (keeps build() tidy + text-scale safe)
/// ---------------------------------------------------------------------------
class _SheetLayoutMetrics {
  final double pinnedHeaderExtent;

  final double grabberHeight;
  final double tabsHeight;
  final double searchHeight;

  final double vPad;
  final double gap;

  const _SheetLayoutMetrics({
    required this.pinnedHeaderExtent,
    required this.grabberHeight,
    required this.tabsHeight,
    required this.searchHeight,
    required this.vPad,
    required this.gap,
  });

  static _SheetLayoutMetrics from({
    required BuildContext context,
    required bool showSearch,
  }) {
    final textScaler = MediaQuery.of(context).textScaler;

    final labelFont = textScaler.scale(12);
    final labelLineHeight = labelFont * 1.35;

    const grabberHeight = 16.0;
    const vPad = 12.0;
    const gap = 10.0;

    // icon + gap + label + padding (matches your original intent)
    final tabsHeight = 32 + 4 + labelLineHeight + 16;

    // your original "scale-aware-ish" search height logic, but named
    final searchHeight = 52 + (textScaler.scale(1) - 1) * 8;

    final headerBaseExtent = vPad + grabberHeight + gap + tabsHeight + vPad;
    final pinnedHeaderExtent =
        showSearch ? headerBaseExtent + gap + searchHeight : headerBaseExtent;

    return _SheetLayoutMetrics(
      pinnedHeaderExtent: pinnedHeaderExtent,
      grabberHeight: grabberHeight,
      tabsHeight: tabsHeight,
      searchHeight: searchHeight,
      vPad: vPad,
      gap: gap,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _SheetLayoutMetrics &&
      pinnedHeaderExtent == other.pinnedHeaderExtent &&
      grabberHeight == other.grabberHeight &&
      tabsHeight == other.tabsHeight &&
      searchHeight == other.searchHeight &&
      vPad == other.vPad &&
      gap == other.gap;

  @override
  int get hashCode => Object.hash(
        pinnedHeaderExtent,
        grabberHeight,
        tabsHeight,
        searchHeight,
        vPad,
        gap,
      );
}

/// ---------------------------------------------------------------------------
///  CONSTANTS / THEME-ish
/// ---------------------------------------------------------------------------
class _SheetConfig {
  static const minChildSize = 0.05;
  static const initialChildSize = 0.5;
  static const maxChildSize = 0.9;
  static const snapSizes = <double>[0.5, 0.9];
}

class _TabIndex {
  static const search = 0;
  static const favorites = 1;
  static const me = 2;
}

class _Spacing {
  static const hPad = 12.0;
}

class _Colors {
  static const headerNavy = Color(0xFF0A3A6B);
  static const handleWhite = Colors.white;

  static const tabActive = Colors.white;
  static const tabInactive = Colors.white70;
}

class _TextStyles {
  static const title = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xff141414),
  );

  static const subtitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    color: Color(0xff3D3D3D),
    fontWeight: FontWeight.w500,
  );
}

/// ---------------------------------------------------------------------------
///  MODEL
/// ---------------------------------------------------------------------------
class Location {
  final String name;
  final String description;
  final String category;

  const Location({
    required this.name,
    required this.description,
    required this.category,
  });

  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q);
  }
}

/// ---------------------------------------------------------------------------
///  SAMPLE DATA
/// ---------------------------------------------------------------------------
final List<Location> searchLocations = [
  Location(
    name: 'Rockefeller',
    description: 'Department of Physics',
    category: 'Building',
  ),
  Location(
    name: 'Wolstein',
    description: 'CWRU Office of Admissions',
    category: 'Building',
  ),
  Location(
    name: 'Mandel Center',
    description:
        'Jack, Joseph, and Morton Mandel Community Center, Admissions Office Welcome Center',
    category: 'Building',
  ),
  Location(
    name: 'Fribley Commons',
    description: 'Southside Area Commons and Dining Hall',
    category: 'Commons',
  ),
];

final List<Location> favoriteLocations = [
  Location(
    name: 'Fribley Commons',
    description: 'Southside Area Commons and Dining Hall',
    category: 'Commons',
  ),
];