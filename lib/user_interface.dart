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
  int _selectedTab = 0;
  final _searchCtrl = TextEditingController();
  String _query = '';

  Location? _selectedLocation;
  final _mainSheetController = DraggableScrollableController();
  double _sizeBeforeDetail = _SheetConfig.initialChildSize;

  // Mutable favorites list — seeded from sample data
  late final List<Location> _favorites = List.of(favoriteLocations);

  late final Map<int, List<Location>> _dataByTab = {
    0: searchLocations,
    1: _favorites,
    2: List.generate(
      8,
      (i) => Location(
        name: 'Profile Item $i',
        description: 'Information related to your profile.',
        category: 'Me',
      ),
    ),
  };

  bool _isFavorite(Location location) =>
      _favorites.any((f) => f.name == location.name);

  void _toggleFavorite(Location location) {
    setState(() {
      if (_isFavorite(location)) {
        _favorites.removeWhere((f) => f.name == location.name);
      } else {
        _favorites.add(location);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _mainSheetController.dispose();
    super.dispose();
  }

  void _selectTab(int tabIndex) {
    setState(() {
      _selectedTab = tabIndex;
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

  void _openDetail(Location location) {
    _sizeBeforeDetail = _mainSheetController.isAttached
        ? _mainSheetController.size
        : _SheetConfig.initialChildSize;
    setState(() => _selectedLocation = location);
    if (_mainSheetController.isAttached &&
        _sizeBeforeDetail > _SheetConfig.initialChildSize) {
      _mainSheetController.jumpTo(_SheetConfig.initialChildSize);
    }
  }

  void _closeDetail() {
    setState(() => _selectedLocation = null);
    if (_mainSheetController.isAttached &&
        _sizeBeforeDetail > _SheetConfig.initialChildSize) {
      _mainSheetController.jumpTo(_sizeBeforeDetail);
    }
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

        // Main search/browse sheet — always present underneath
        ScrollConfiguration(
          behavior: _MouseDragScrollBehavior(),
          child: DraggableScrollableSheet(
          controller: _mainSheetController,
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
                  _ResultsList(
                    items: filtered,
                    onTapLocation: _openDetail,
                  ),
                ],
              ),
            );
          },
          ),
        ),

        // Detail sheet — slides over the search sheet when a location is tapped
        if (_selectedLocation != null)
          _LocationDetailSheet(
            location: _selectedLocation!,
            onBack: _closeDetail,
            isFavorite: _isFavorite(_selectedLocation!),
            onFavoriteToggle: () => _toggleFavorite(_selectedLocation!),
          ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
///  LOCATION DETAIL SHEET
/// ---------------------------------------------------------------------------
class _LocationDetailSheet extends StatefulWidget {
  const _LocationDetailSheet({
    required this.location,
    required this.onBack,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final Location location;
  final VoidCallback onBack;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  State<_LocationDetailSheet> createState() => _LocationDetailSheetState();
}

class _LocationDetailSheetState extends State<_LocationDetailSheet> {
  String? _selectedEntrance;

  @override
  void initState() {
    super.initState();
    if (widget.location.entrances.isNotEmpty) {
      _selectedEntrance = widget.location.entrances.first;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = widget.location;

    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        widthFactor: 1.0,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Pinned header
                _DetailHeader(
                  location: location,
                  onBack: widget.onBack,
                  isFavorite: widget.isFavorite,
                  onFavoriteToggle: widget.onFavoriteToggle,
                ),
                const Divider(height: 1),

                // Scrollable middle content
                Expanded(
                  child: ScrollConfiguration(
                    behavior: _MouseDragScrollBehavior(),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _DetailNavRow(
                          icon: Icons.description_outlined,
                          label: 'Description',
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _DetailNavRow(
                          icon: Icons.map_outlined,
                          label: 'Floor plans',
                          onTap: () {},
                        ),

                        if (location.entrances.isNotEmpty) ...[
                          _SectionHeader(title: 'ENTRANCES'),
                          ...location.entrances.map(
                            (e) => _EntranceRow(
                              label: e,
                              highlighted: e == _selectedEntrance,
                              onTap: () =>
                                  setState(() => _selectedEntrance = e),
                            ),
                          ),
                        ],

                        if (location.rooms.isNotEmpty) ...[
                          _SectionHeader(title: 'ROOMS'),
                          ...location.rooms.map((r) => _RoomRow(label: r)),
                        ],
                      ],
                    ),
                  ),
                ),

                // Always-visible pinned DIRECTIONS button
                _DirectionsButton(onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.location,
    required this.onBack,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  final Location location;
  final VoidCallback onBack;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Column(
        children: [
          // Back arrow + title + star row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: _Colors.headerNavy),
                  onPressed: onBack,
                  tooltip: 'Back',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _Colors.headerNavy,
                        ),
                      ),
                      if (location.description.isNotEmpty)
                        Text(
                          location.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? const Color(0xFFFFC107) : Colors.black45,
                    size: 28,
                  ),
                  onPressed: onFavoriteToggle,
                  tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailNavRow extends StatelessWidget {
  const _DetailNavRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF444444), size: 22),
        title: Text(label, style: _TextStyles.title),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF444444)),
        onTap: onTap,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EntranceRow extends StatelessWidget {
  const _EntranceRow({
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: highlighted ? const Color(0xFFDDE8F5) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: highlighted ? _Colors.headerNavy : Colors.black87,
            fontWeight: highlighted ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
    );
  }
}

class _DirectionsButton extends StatelessWidget {
  const _DirectionsButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _Colors.headerNavy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'DIRECTIONS',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
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
///  RESULTS LIST
/// ---------------------------------------------------------------------------
class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.items, required this.onTapLocation});
  final List<Location> items;
  final ValueChanged<Location> onTapLocation;

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
        (context, i) => _LocationTile(
          location: items[i],
          onTap: () => onTapLocation(items[i]),
        ),
        childCount: items.length,
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.location, required this.onTap});
  final Location location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined),
      title: Text(location.name, style: _TextStyles.title),
      subtitle: Text(location.description, style: _TextStyles.subtitle),
      onTap: onTap,
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

// Dark grabber for the white detail sheet
class _GrabberDark extends StatelessWidget {
  const _GrabberDark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(2),
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
      children: const [],
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
///  LAYOUT METRICS
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

    final tabsHeight = 32 + 4 + labelLineHeight + 16;
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
///  MOUSE DRAG SCROLL BEHAVIOR
/// ---------------------------------------------------------------------------
class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
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
  final List<String> entrances;
  final List<String> rooms;

  const Location({
    required this.name,
    required this.description,
    required this.category,
    this.entrances = const [],
    this.rooms = const [],
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
    entrances: [
      'Front entrance (Euclid Ave)',
      'Side entrance (near quad)',
    ],
    rooms: ['101', '102', '201', '202'],
  ),
  Location(
    name: 'Wolstein',
    description: 'CWRU Office of Admissions',
    category: 'Building',
    entrances: [
      'Main entrance (Adelbert Rd)',
    ],
    rooms: ['100', '110'],
  ),
  Location(
    name: 'Mandel Center',
    description:
        'Jack, Joseph, and Morton Mandel Community Center, Admissions Office Welcome Center',
    category: 'Building',
    entrances: [
      'Front-right entrance (near intersection)',
      'Front-left entrance (near humanities quad)',
      'Back entrance (near Law School)',
    ],
    rooms: ['101', '102'],
  ),
  Location(
    name: 'Fribley Commons',
    description: 'Southside Area Commons and Dining Hall',
    category: 'Commons',
    entrances: [
      'Main entrance (south side)',
      'Side entrance (parking lot)',
    ],
    rooms: [],
  ),
];

final List<Location> favoriteLocations = [
  Location(
    name: 'Fribley Commons',
    description: 'Southside Area Commons and Dining Hall',
    category: 'Commons',
    entrances: [
      'Main entrance (south side)',
      'Side entrance (parking lot)',
    ],
    rooms: [],
  ),
];
