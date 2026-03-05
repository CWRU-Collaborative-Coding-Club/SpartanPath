import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(const SpartanPathApp());

/// ---------------------------------------------------------------------------
///  APP
///  Root of the application. Sets up Material theming and launches the main
///  screen. The seed color drives the light-blue background palette.
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
///  The top-level screen widget. Kept as a StatefulWidget so its state class
///  can manage the main sheet position, selected location, and favorites.
/// ---------------------------------------------------------------------------
class SpartanPathSheetDemo extends StatefulWidget {
  const SpartanPathSheetDemo({super.key});

  @override
  State<SpartanPathSheetDemo> createState() => _SpartanPathSheetDemoState();
}

class _SpartanPathSheetDemoState extends State<SpartanPathSheetDemo> {
  /// Which tab is currently selected: 0 = Search, 1 = Favorites, 2 = Me.
  int _selectedTab = 0;

  /// Controller and query string for the search text field.
  final _searchCtrl = TextEditingController();
  String _query = '';

  /// The location currently shown in the detail sheet.
  /// null means the detail sheet is hidden and the main sheet is active.
  Location? _selectedLocation;

  /// Controls the main search sheet's position programmatically, allowing
  /// us to jump it to a specific snap position when opening/closing details.
  final _mainSheetController = DraggableScrollableController();

  /// Stores where the main sheet was before a detail view was opened,
  /// so we can restore it to the correct position when the detail is closed.
  double _sizeBeforeDetail = _SheetConfig.initialChildSize;

  /// The user's current favorites list. Seeded from [favoriteLocations] but
  /// mutated at runtime as the user toggles the star on location detail sheets.
  /// Stored here (rather than in the detail sheet) so the Favorites tab
  /// always reflects the latest state.
  late final List<Location> _favorites = List.of(favoriteLocations);

  /// Maps each tab index to the list of locations it should display.
  /// The favorites tab points directly at [_favorites] so it updates live.
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

  /// Returns true if [location] is currently in the favorites list.
  /// Matches by name since Location has no unique ID yet.
  bool _isFavorite(Location location) =>
      _favorites.any((f) => f.name == location.name);

  /// Adds or removes [location] from [_favorites] and triggers a rebuild
  /// so the star icon and Favorites tab both update immediately.
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

  /// Switches the active tab. Clears the search query when leaving the
  /// Search tab so stale results don't appear when returning.
  void _selectTab(int tabIndex) {
    setState(() {
      _selectedTab = tabIndex;
      if (tabIndex != _TabIndex.search) {
        _query = '';
        _searchCtrl.clear();
      }
    });
  }

  /// Returns the filtered list of locations for the current tab.
  /// If the search query is empty, all items for the tab are returned.
  List<Location> _filteredItems() {
    final items = _dataByTab[_selectedTab] ?? const <Location>[];
    final q = _query.trim();
    if (q.isEmpty) return items;
    return items.where((loc) => loc.matchesQuery(q)).toList();
  }

  /// Opens the detail sheet for [location].
  /// Records the main sheet's current position before doing anything.
  /// If the main sheet was above 50%, it jumps it down to 50% so it sits
  /// neatly behind the detail sheet without overlapping it.
  void _openDetail(Location location) {
    _sizeBeforeDetail = _mainSheetController.isAttached
        ? _mainSheetController.size
        : _SheetConfig.initialChildSize;
    setState(() => _selectedLocation = location);
    if (_mainSheetController.isAttached &&
        _sizeBeforeDetail > _SheetConfig.initialChildSize) {
      _mainSheetController.jumpTo(_SheetConfig.initialChildSize);
    }
    // If the main sheet was already at or below 50%, leave it in place —
    // the detail sheet will appear directly on top.
  }

  /// Closes the detail sheet and restores the main sheet.
  /// If the main sheet was above 50% before the detail opened, it jumps
  /// back to that position instantly. Otherwise no movement is needed
  /// because the main sheet was never moved.
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

    // Recalculate header height whenever the tab or text scale changes.
    final metrics = _SheetLayoutMetrics.from(
      context: context,
      showSearch: showSearch,
    );
    final filtered = _filteredItems();

    return Stack(
      children: [
        // The map/background content sits at the bottom of the stack.
        // In the future this will be replaced by an interactive map widget.
        _Background(scheme: scheme),

        // The main search/browse sheet. It sits above the background and
        // can be dragged between a minimized peek (5%), half-open (50%),
        // and fully expanded (90%) position.
        ScrollConfiguration(
          // Extend drag support to mouse, stylus, and trackpad in addition
          // to the default touch-only behaviour.
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
                    // The tab bar (and optional search field) stays pinned
                    // at the top of the sheet while the list scrolls beneath.
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
                    // The scrollable list of locations for the active tab.
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

        // The detail sheet is conditionally rendered on top of everything
        // when a location has been selected. Closing it sets _selectedLocation
        // back to null, removing this widget from the tree entirely.
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
///  A fixed-height panel anchored to the bottom half of the screen, showing
///  the full details for a selected location. It is not draggable — its
///  position is always exactly 50% of the screen height, leaving the top half
///  free for the map view that will be added in a future iteration.
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

  /// Whether this location is currently in the user's favorites list.
  /// Passed in from the parent so the star reflects the shared favorites state.
  final bool isFavorite;

  /// Called when the user taps the star icon to toggle the favorite status.
  final VoidCallback onFavoriteToggle;

  @override
  State<_LocationDetailSheet> createState() => _LocationDetailSheetState();
}

class _LocationDetailSheetState extends State<_LocationDetailSheet> {
  /// The entrance currently highlighted in blue. Defaults to the first
  /// entrance in the list when the sheet opens.
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

    // Align to the bottom and size to exactly half the screen height.
    // widthFactor: 1.0 ensures it stretches edge to edge.
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: 0.5,
        widthFactor: 1.0,
        child: ClipRRect(
          // Rounded top corners to match the main sheet style.
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Fixed header: back arrow, location name/subtitle, and
                // the favorite star toggle. Does not scroll.
                _DetailHeader(
                  location: location,
                  onBack: widget.onBack,
                  isFavorite: widget.isFavorite,
                  onFavoriteToggle: widget.onFavoriteToggle,
                ),
                const Divider(height: 1),

                // Scrollable body: description, floor plans, entrances,
                // and rooms. Uses _MouseDragScrollBehavior so it can be
                // scrolled with a mouse drag as well as touch.
                Expanded(
                  child: ScrollConfiguration(
                    behavior: _MouseDragScrollBehavior(),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // Tappable row that will open a description view.
                        _DetailNavRow(
                          icon: Icons.description_outlined,
                          label: 'Description',
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        // Tappable row that will open floor plan images.
                        _DetailNavRow(
                          icon: Icons.map_outlined,
                          label: 'Floor plans',
                          onTap: () {},
                        ),

                        // Entrances section — only shown if the location
                        // has at least one entrance defined.
                        if (location.entrances.isNotEmpty) ...[
                          _SectionHeader(title: 'ENTRANCES'),
                          // Each entrance can be tapped to highlight it in
                          // blue, indicating the user's chosen entry point.
                          ...location.entrances.map(
                            (e) => _EntranceRow(
                              label: e,
                              highlighted: e == _selectedEntrance,
                              onTap: () =>
                                  setState(() => _selectedEntrance = e),
                            ),
                          ),
                        ],

                        // Rooms section — only shown if the location has
                        // at least one room number defined.
                        if (location.rooms.isNotEmpty) ...[
                          _SectionHeader(title: 'ROOMS'),
                          ...location.rooms.map((r) => _RoomRow(label: r)),
                        ],
                      ],
                    ),
                  ),
                ),

                // The DIRECTIONS button is always visible at the bottom of
                // the sheet, outside the scrollable area, so it is never
                // hidden by content.
                _DirectionsButton(onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  DETAIL HEADER
///  The non-scrolling top bar of the detail sheet. Shows a back arrow on the
///  left, the location name and description subtitle in the centre, and a
///  star button on the right to toggle the location as a favorite.
/// ---------------------------------------------------------------------------
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
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back arrow — dismisses the detail sheet and returns to
                // the main search sheet.
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: _Colors.headerNavy),
                  onPressed: onBack,
                  tooltip: 'Back',
                ),
                const SizedBox(width: 4),
                // Location name and description, allowed to expand and
                // truncate if the text is too long.
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
                // Star toggle: outlined when not a favorite, filled amber
                // when the location has been added to favorites.
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite
                        ? const Color(0xFFFFC107)
                        : Colors.black45,
                    size: 28,
                  ),
                  onPressed: onFavoriteToggle,
                  tooltip: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  DETAIL NAV ROW
///  A tappable list row used for Description and Floor Plans in the detail
///  sheet. Renders with a leading icon, a label, and a chevron on the right
///  to indicate that tapping will navigate somewhere.
/// ---------------------------------------------------------------------------
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

/// ---------------------------------------------------------------------------
///  SECTION HEADER
///  A bold, uppercase label used to introduce grouped content in the detail
///  sheet (e.g. "ENTRANCES", "ROOMS").
/// ---------------------------------------------------------------------------
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

/// ---------------------------------------------------------------------------
///  ENTRANCE ROW
///  A tappable row representing a single entrance to a location. When tapped,
///  the row is highlighted in blue to indicate it is the user's selected
///  entrance. Only one entrance can be highlighted at a time.
/// ---------------------------------------------------------------------------
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
        // Blue tint background when selected, plain white otherwise.
        color: highlighted ? const Color(0xFFDDE8F5) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: highlighted ? _Colors.headerNavy : Colors.black87,
            fontWeight:
                highlighted ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
OAOAOA///  ROOM ROW
OAOAOA///  A simple non-interactive row that displays a room number or label within
///  the Rooms section of the detail sheet.
/// ---------------------------------------------------------------------------
class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.label});
OAOAOA  final String label;

  @override
OAOAOA  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        label,
OAOAOA        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  DIRECTIONS BUTTON
///  A full-width navy button pinned to the bottom of the detail sheet.
///  Will eventually launch turn-by-turn directions to the selected location.
/// ---------------------------------------------------------------------------
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
///  Fills the entire screen behind the sheets. This will be replaced with a
///  live map widget in a future iteration. For now it just renders a
///  placeholder label over the app's primary container colour.
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
///  FROSTED SHEET
///  The wrapper used by the main search sheet. Applies rounded top corners,
///  a backdrop blur, and a semi-transparent white fill so the background
///  (map) can faintly show through.
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
///  Renders the list of locations for the currently active tab as a sliver,
///  so it can scroll inside the main sheet's CustomScrollView. Shows a "No
///  results" message if the filtered list is empty.
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

/// A single row in the results list. Displays the location icon, name, and
/// description. Tapping it opens the detail sheet for that location.
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
///  TOP HEADER DELEGATE
///  A SliverPersistentHeaderDelegate that keeps the tab bar (and optional
///  search field) pinned at the top of the main sheet as the list scrolls.
///  The header height is calculated by [_SheetLayoutMetrics] to account for
///  text scaling and whether the search field is currently visible.
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

  /// Whether to show the search field below the tab bar. True only on the
  /// Search tab.
  final bool showSearch;
  final int selectedTab;
  final ValueChanged<int> onSelectTab;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final _SheetLayoutMetrics metrics;

  /// Fixed height — the header does not shrink or grow as the user scrolls.
  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
            // White pill handle indicating the sheet is draggable.
            _Grabber(height: metrics.grabberHeight),
            SizedBox(height: metrics.gap),

            // Search / Favorites / Me tab buttons.
            SizedBox(
              height: metrics.tabsHeight,
              child: _TabsRow(
                selectedTab: selectedTab,
                onSelectTab: onSelectTab,
              ),
            ),

            // Search field is only rendered on the Search tab.
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

  /// Only rebuild if something that affects the header's appearance changed.
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
///  GRABBER
///  The small white pill rendered at the top of the main sheet header to
///  signal to users that the sheet can be dragged up or down.
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

/// A dark-coloured grabber pill used on white-background sheets.
/// Currently unused since the detail sheet is no longer draggable, but
/// kept here in case it is needed again in future.
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

/// ---------------------------------------------------------------------------
///  TABS ROW
///  Renders the three navigation tabs (Search, Favorites, Me) evenly spaced
///  across the header. Delegates selection handling to [_TabIconButton].
/// ---------------------------------------------------------------------------
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

/// Helper extension that lets us build the Row's children list separately
/// from the Row constructor, keeping [_TabsRow.build] readable.
extension on Row {
  Row _withChildren(List<Widget> children) {
    return Row(mainAxisAlignment: mainAxisAlignment, children: children);
  }
}

/// ---------------------------------------------------------------------------
///  TAB ICON BUTTON
///  A single tab in the header. Renders an icon above a text label, both
///  coloured white when selected and white70 when inactive.
/// ---------------------------------------------------------------------------
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
                // Bold when selected to reinforce the active state.
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
///  SEARCH FIELD
///  The text input rendered below the tab bar on the Search tab. Includes a
///  search icon prefix and a clear button suffix. Dismisses the keyboard when
///  the user submits.
/// ---------------------------------------------------------------------------
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
///  SHEET LAYOUT METRICS
///  Calculates the pixel height of the pinned header in the main sheet,
///  taking the device's text scale factor into account so the header never
///  clips its content on larger font sizes. Passed into [_TopHeaderDelegate]
///  as a single immutable object to simplify equality checks and rebuilds.
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

    // 1.35 is a standard line-height multiplier for body-sized text.
    final labelLineHeight = labelFont * 1.35;

    const grabberHeight = 16.0;
    const vPad = 12.0;
    const gap = 10.0;

    // Tab button height = icon (32) + gap (4) + label line height + vertical
    // padding inside the button (16 total).
    final tabsHeight = 32 + 4 + labelLineHeight + 16;

    // Search field height grows slightly with text scale to avoid clipping.
    final searchHeight = 52 + (textScaler.scale(1) - 1) * 8;

    final headerBaseExtent = vPad + grabberHeight + gap + tabsHeight + vPad;

    // Add the search field height only when on the Search tab.
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

  /// Equality is used by [_TopHeaderDelegate.shouldRebuild] to avoid
  /// unnecessary header rebuilds when the metrics have not changed.
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
///  Extends Flutter's default MaterialScrollBehavior to recognise mouse,
///  stylus, and trackpad drag gestures in addition to touch. Applied to both
///  the main sheet's DraggableScrollableSheet and the detail sheet's
///  scrollable body so all input devices can scroll and drag the UI.
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
///  SHEET CONFIG
///  Named constants controlling the snap positions of the main sheet.
///  minChildSize     — peeking state, just enough to show the grabber handle.
///  initialChildSize — default half-open state on app launch.
///  maxChildSize     — fully expanded state, covering 90% of the screen.
/// ---------------------------------------------------------------------------
class _SheetConfig {
  static const minChildSize = 0.05;
  static const initialChildSize = 0.5;
  static const maxChildSize = 0.9;

  /// The sheet snaps to these two positions; it will not rest at any other
  /// height after the user releases their drag.
  static const snapSizes = <double>[0.5, 0.9];
}

/// ---------------------------------------------------------------------------
///  TAB INDEX
///  Named constants for the three main navigation tabs, used throughout the
///  codebase instead of raw integers for clarity.
/// ---------------------------------------------------------------------------
class _TabIndex {
  static const search = 0;
  static const favorites = 1;
  static const me = 2;
}

/// ---------------------------------------------------------------------------
///  SPACING
/// ---------------------------------------------------------------------------
class _Spacing {
  /// Horizontal padding applied inside the main sheet header.
  static const hPad = 12.0;
}

/// ---------------------------------------------------------------------------
///  COLORS
/// ---------------------------------------------------------------------------
class _Colors {
  /// Primary navy used for the header background, title text, and the
  /// Directions button background.
  static const headerNavy = Color(0xFF0A3A6B);

  /// White pill handle shown on the navy header.
  static const handleWhite = Colors.white;

  /// Icon and label colour for the active tab.
  static const tabActive = Colors.white;

  /// Icon and label colour for inactive tabs — slightly dimmed.
  static const tabInactive = Colors.white70;
}

/// ---------------------------------------------------------------------------
///  TEXT STYLES
///  Shared text styles used across multiple widgets to keep typography
///  consistent without repeating style definitions inline.
/// ---------------------------------------------------------------------------
class _TextStyles {
  /// Primary label style for location names and nav row labels.
  static const title = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xff141414),
  );

  /// Secondary label style for descriptions and subtitles.
  static const subtitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    color: Color(0xff3D3D3D),
    fontWeight: FontWeight.w500,
  );
}

/// ---------------------------------------------------------------------------
///  LOCATION MODEL
///  Represents a single campus location. [entrances] and [rooms] are
///  optional — widgets that display them check [isNotEmpty] before rendering
///  their respective sections.
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

  /// Returns true if any of the location's fields contain [query] as a
  /// case-insensitive substring. Used to filter the results list.
  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q);
  }
}

/// ---------------------------------------------------------------------------
///  SAMPLE DATA
///  Placeholder locations used during development. In production these would
///  be fetched from a backend API or a local database.
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

/// The initial set of favorited locations. Loaded into the mutable
/// [_SpartanPathSheetDemoState._favorites] list at startup.
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
