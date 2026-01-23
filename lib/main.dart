import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(const DraggableScrollableSheetExampleApp());

class DraggableScrollableSheetExampleApp extends StatelessWidget {
  const DraggableScrollableSheetExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade100),
        useMaterial3: true,
      ),
      home: const Scaffold(body: DraggableScrollableSheetExample()),
    );
  }
}

class DraggableScrollableSheetExample extends StatefulWidget {
  const DraggableScrollableSheetExample({super.key});

  @override
  State<DraggableScrollableSheetExample> createState() =>
      _DraggableScrollableSheetExampleState();
}

class _DraggableScrollableSheetExampleState
    extends State<DraggableScrollableSheetExample> {
  int _selectedTab = 0; // 0=Search, 1=Favorites, 2=Me
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final Map<int, List<Location>> _dataByTab = {
    0: searchLocations,
    1: favoriteLocations,
    2: List.generate(
      8,
      (i) => Location(
        name: 'Profile Location $i',
        description: 'Location related to your profile.',
        category: 'Me',
      ),
    ),
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // ----- Dynamic sizing (text-scale safe) -----
    final textScaler = MediaQuery.of(context).textScaler;
    final double labelFont = textScaler.scale(12);
    final double labelLineHeight = labelFont * 1.35;
    const double grabberHeight = 16;
    final double tabsHeight =
        32 + 4 + labelLineHeight + 16; // icon+gap+label+pad
    final double searchHeight = 52 + (textScaler.scale(1) - 1) * 8;
    const double vPad = 12;
    const double gap = 10;

    final bool showSearch = _selectedTab == 0;

    // base: grabber + gap + tabs + vPad
    final double headerBaseExtent =
        vPad + grabberHeight + gap + tabsHeight + vPad;

    // if search tab, add gap + searchHeight
    final double pinnedHeaderExtent = showSearch
        ? headerBaseExtent + gap + searchHeight
        : headerBaseExtent;

    // Data filtering
    final List<Location> items = _dataByTab[_selectedTab] ?? const [];
    final String q = _query.trim();
    final List<Location> filtered = q.isEmpty
        ? items
        : items.where((loc) => loc.matchesQuery(q)).toList();

    return Stack(
      children: [
        // Background content
        Container(
          color: colorScheme.primaryContainer,
          alignment: Alignment.center,
          child: Text(
            'Background Content',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),

        // DraggableScrollableSheet
        DraggableScrollableSheet(
          minChildSize: 0.05,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          snap: true,
          snapSizes: const [0.5, 0.9],
          builder: (context, scrollController) {
            // Keep header solid; make only the body translucent + blurred
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withValues(
                    alpha: 0.85,
                  ), // translucent body
                  child: CustomScrollView(
                    controller: scrollController, // required for snapping
                    slivers: [
                      // One pinned header: grabber + tabs + (optional) search
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _TopHeaderDelegate(
                          extent: pinnedHeaderExtent,
                          grabberHeight: grabberHeight,
                          tabsHeight: tabsHeight,
                          searchHeight: searchHeight,
                          vPad: vPad,
                          gap: gap,
                          showSearch: showSearch,
                          selectedTab: _selectedTab,
                          onSelectTab: (i) {
                            setState(() {
                              _selectedTab = i;
                              // Optional: clear query when leaving Search tab
                              if (i != 0) {
                                _query = '';
                                _searchCtrl.clear();
                              }
                            });
                          },
                          searchController: _searchCtrl,
                          onQueryChanged: (s) => setState(() => _query = s),
                        ),
                      ),

                      const SliverToBoxAdapter(child: Divider(height: 1)),

                      // Results
                      if (filtered.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('No results'),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final loc = filtered[i];
                            return ListTile(
                              title: Text(
                                loc.name,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff141414),
                                ),
                              ),
                              subtitle: Text(
                                loc.description,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xff3D3D3D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              leading: const Icon(Icons.location_on_outlined),
                            );
                          }, childCount: filtered.length),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
///  ONE PINNED HEADER (seamless): Grabber + Tabs + optional Search
/// ---------------------------------------------------------------------------
class _TopHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TopHeaderDelegate({
    required this.extent,
    required this.grabberHeight,
    required this.tabsHeight,
    required this.searchHeight,
    required this.vPad,
    required this.gap,
    required this.showSearch,
    required this.selectedTab,
    required this.onSelectTab,
    required this.searchController,
    required this.onQueryChanged,
  });

  final double extent;
  final double grabberHeight;
  final double tabsHeight;
  final double searchHeight;
  final double vPad;
  final double gap;
  final bool showSearch;

  final int selectedTab;
  final ValueChanged<int> onSelectTab;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;

  static const Color headerColor = Color(0xFF0A3A6B); // solid navy

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    const Color handleColor = Colors.white;

    return Material(
      color: headerColor,
      elevation: 0, // seamless
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: vPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grabber
            SizedBox(
              height: grabberHeight,
              child: Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            SizedBox(height: gap),

            // Tabs
            SizedBox(
              height: tabsHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _TabIconButton(
                    icon: Icons.search,
                    label: 'Search',
                    selected: selectedTab == 0,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white70,
                    onTap: () => onSelectTab(0),
                  ),
                  _TabIconButton(
                    icon: Icons.star,
                    label: 'Favorites',
                    selected: selectedTab == 1,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white70,
                    onTap: () => onSelectTab(1),
                  ),
                  _TabIconButton(
                    icon: Icons.person,
                    label: 'Me',
                    selected: selectedTab == 2,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white70,
                    onTap: () => onSelectTab(2),
                  ),
                ],
              ),
            ),

            // Only show gap + search bar on Search tab
            if (showSearch) ...[
              SizedBox(height: gap),
              SizedBox(
                height: searchHeight,
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  cursorColor: const Color(0xFF0A3A6B),
                  style: const TextStyle(color: Colors.black87),
                  onChanged: onQueryChanged,
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: const TextStyle(color: Colors.black45),
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    suffixIcon: IconButton(
                      onPressed: () {
                        searchController.clear();
                        onQueryChanged('');
                      },
                      icon: const Icon(Icons.clear, color: Colors.black54),
                      tooltip: 'Clear',
                    ),
                    filled: true,
                    fillColor: Colors.white, // solid white field
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
    return old.extent != extent ||
        old.selectedTab != selectedTab ||
        old.showSearch != showSearch ||
        old.searchController != searchController ||
        old.tabsHeight != tabsHeight ||
        old.searchHeight != searchHeight ||
        old.grabberHeight != grabberHeight ||
        old.vPad != vPad ||
        old.gap != gap;
  }
}

/// ---------------------------------------------------------------------------
///  TAB ICON BUTTON
/// ---------------------------------------------------------------------------
class _TabIconButton extends StatelessWidget {
  const _TabIconButton({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white70,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? activeColor : inactiveColor;
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

class Location {
  final String name;
  final String description;
  final String category;

  const Location({
    required this.name,
    required this.description,
    required this.category,
  });

  /// Simple helper so we can call location.matchesQuery(query)
  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q);
  }
}

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

List<Location> favoriteLocations = [
  Location(
    name: 'Fribley Commons',
    description: 'Southside Area Commons and Dining Hall',
    category: 'Commons',
  ),
];
