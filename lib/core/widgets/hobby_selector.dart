import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphic_container/glassmorphic_container.dart';

// Huge list of dating-app friendly hobbies (100+ real ones)
const List<String> allHobbies = [
  "Hiking", "Traveling", "Reading", "Gaming", "Cooking", "Gym", "Yoga", "Photography",
  "Music", "Dancing", "Movies", "Netflix & Chill", "Sports", "Football", "Basketball",
  "Swimming", "Cycling", "Running", "Painting", "Drawing", "Writing", "Podcasts",
  "Tech", "Coding", "Crypto", "Cars", "Motorcycles", "Fishing", "Camping", "Concerts",
  "Festivals", "Wine Tasting", "Coffee", "Craft Beer", "Board Games", "Video Games",
  "Anime", "K-Pop", "Rock Climbing", "Skiing", "Snowboarding", "Surfing", "Skateboarding",
  "Martial Arts", "Meditation", "Astrology", "Tarot", "Gardening", "Baking", "Fashion",
  "Makeup", "Tattoos", "Piercings", "Dogs", "Cats", "Animals", "Volunteering", "Books",
  "Sci-Fi", "Fantasy", "True Crime", "Stand-up Comedy", "Theater", "Live Music", "DJing",
  "Singing", "Guitar", "Piano", "Drums", "Language Learning", "Chess", "Poker", "Trivia",
  "Escape Rooms", "Bowling", "Mini Golf", "Theme Parks", "Road Trips", "Beach Days",
  "Mountain Climbing", "Kayaking", "Scuba Diving", "Skydiving", "Bungee Jumping",
  "Foodie", "Vegan", "Keto", "Healthy Eating", "Sustainability", "Minimalism"
];

class HobbySelector extends StatefulWidget {
  final List<String> initialSelected;
  final Function(List<String>) onChanged; // Hook to save to Firebase/Provider

  const HobbySelector({
    super.key,
    this.initialSelected = const [],
    required this.onChanged,
  });

  @override
  State<HobbySelector> createState() => _HobbySelectorState();
}

class _HobbySelectorState extends State<HobbySelector> {
  final TextEditingController _searchController = TextEditingController();
  List<String> selectedHobbies = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    selectedHobbies = List.from(widget.initialSelected);
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.toLowerCase());
    });
  }

  List<String> get filteredHobbies {
    if (searchQuery.isEmpty) return allHobbies;
    return allHobbies
        .where((hobby) => hobby.toLowerCase().contains(searchQuery))
        .toList();
  }

  void toggleHobby(String hobby) {
    setState(() {
      if (selectedHobbies.contains(hobby)) {
        selectedHobbies.remove(hobby);
      } else if (selectedHobbies.length < 15) { // optional max
        selectedHobbies.add(hobby);
      }
    });
    widget.onChanged(selectedHobbies);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected Interests (glowing removable chips)
        Text("Your Interests", style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedHobbies.map((hobby) {
            return Animate(
              effects: [ScaleEffect(duration: 200.ms)],
              child: GlassmorphicContainer(
                width: null,
                height: 42,
                borderRadius: 30,
                blur: 15,
                linearGradient: LinearGradient(
                  colors: [primary.withOpacity(0.3), secondary.withOpacity(0.2)],
                ),
                borderGradient: LinearGradient(colors: [primary, secondary]),
                child: Chip(
                  label: Text(hobby, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  backgroundColor: Colors.transparent,
                  deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white),
                  onDeleted: () => toggleHobby(hobby),
                  side: BorderSide.none,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Search Bar
        GlassmorphicContainer(
          width: double.infinity,
          height: 56,
          borderRadius: 30,
          blur: 20,
          linearGradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.transparent]),
          borderGradient: LinearGradient(colors: [primary, secondary]),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Search 100+ hobbies & interests...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Filtered Hobby Chips
        SizedBox(
          height: 280,
          child: filteredHobbies.isEmpty
              ? const Center(child: Text("No matches found 😔", style: TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filteredHobbies.map((hobby) {
                      final isSelected = selectedHobbies.contains(hobby);
                      return Animate(
                        effects: [FadeEffect(), ScaleEffect()],
                        child: FilterChip(
                          label: Text(hobby),
                          selected: isSelected,
                          onSelected: (_) => toggleHobby(hobby),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          selectedColor: primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          side: BorderSide(color: isSelected ? Colors.transparent : secondary.withOpacity(0.5)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}
