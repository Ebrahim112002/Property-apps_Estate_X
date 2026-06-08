import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/property_model.dart';
import '../../profile/screens/Dashboard/Hooks/property_details_page.dart'; // 👈 PropertyDetailsPage dynamic path

class HomeSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onFilterTap;
  final ValueChanged<String>? onChanged;
  final List<Property> allProperties; // 👈 Filter korar jonno full property list pass korte hobe

  const HomeSearchBar({
    super.key,
    required this.controller,
    this.onFilterTap,
    this.onChanged,
    required this.allProperties, // 👈 Required kora holo
  });

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Property> _filteredSuggestions = [];
  bool _isDropdownVisible = false;

  @override
  void initState() {
    super.initState();
    // Text input closely observe korar jonno listener
    widget.controller.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSearchTextChanged);
    _hideOverlay();
    super.dispose();
  }

  void _onSearchTextChanged() {
    final query = widget.controller.text.trim();
    if (query.isEmpty) {
      _hideOverlay();
    } else {
      // Title ba Location compare kore query list banano
      final suggestions = widget.allProperties.where((property) {
        return property.title.toLowerCase().contains(query.toLowerCase()) ||
            property.location.toLowerCase().contains(query.toLowerCase());
      }).toList();

      setState(() {
        _filteredSuggestions = suggestions;
      });

      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isDropdownVisible = true);
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      if (mounted) {
        setState(() => _isDropdownVisible = false);
      }
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 8), // Search bar-er thik 8 pixel niche show korbe
          child: Material(
            elevation: 8,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300), // Dropdown tar maximum un-expanded height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: _filteredSuggestions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Text(
                        "No matches found",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: _filteredSuggestions.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
                      itemBuilder: (context, index) {
                        final property = _filteredSuggestions[index];
                        return InkWell(
                          onTap: () {
                            _hideOverlay();
                            FocusScope.of(context).unfocus(); // Keyboard close hobe
                            
                            // Shoraswori Details page navigation connection!
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PropertyDetailsPage(
                                  property: property.toJson(),
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                // Thumbnail Image section with placeholder
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    property.imageUrls.isNotEmpty ? property.imageUrls.first : '',
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Title ar Location text wrap
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        property.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        property.location,
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dropdown target point align rakhar jonno link bind kora holo
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  hintText: "Search your home...",
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.grey),
                  // Dropdown list visible thakle suffix a ekti clear 'cross' trigger thakbe
                  suffixIcon: _isDropdownVisible
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                          onPressed: () {
                            widget.controller.clear();
                            _hideOverlay();
                          },
                        )
                      : null,
                ),
              ),
            ),
            GestureDetector(
              onTap: widget.onFilterTap,
              child: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}