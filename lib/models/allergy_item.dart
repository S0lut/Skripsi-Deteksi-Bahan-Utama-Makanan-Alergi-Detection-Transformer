class AllergyItem {
  final String id;
  final String name;
  final String emoji;
  final String iconAsset; // SVG asset path
  bool isSelected;

  AllergyItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.iconAsset,
    this.isSelected = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'iconAsset': iconAsset,
        'isSelected': isSelected,
      };

  factory AllergyItem.fromJson(Map<String, dynamic> json) => AllergyItem(
        id: json['id'],
        name: json['name'],
        emoji: json['emoji'] ?? '',
        iconAsset: json['iconAsset'] ?? 'assets/icons/shrimp.svg',
        isSelected: json['isSelected'] ?? false,
      );

  AllergyItem copyWith({bool? isSelected}) => AllergyItem(
        id: id,
        name: name,
        emoji: emoji,
        iconAsset: iconAsset,
        isSelected: isSelected ?? this.isSelected,
      );

  static List<AllergyItem> get defaultItems => [
        AllergyItem(id: 'udang',       name: 'Udang',      emoji: '🦐', iconAsset: 'assets/icons/shrimp.svg'),
        AllergyItem(id: 'kepiting',    name: 'Kepiting',   emoji: '🦀', iconAsset: 'assets/icons/crab.svg'),
        AllergyItem(id: 'kerang',      name: 'Kerang',     emoji: '🦪', iconAsset: 'assets/icons/clam.svg'),
        AllergyItem(id: 'telur',       name: 'Telur',      emoji: '🥚', iconAsset: 'assets/icons/egg.svg'),
        AllergyItem(id: 'tahu',        name: 'Tahu',       emoji: '🟫', iconAsset: 'assets/icons/tofu.svg'),
        AllergyItem(id: 'tempe',       name: 'Tempe',      emoji: '🟤', iconAsset: 'assets/icons/tempe.svg'),
        AllergyItem(id: 'kacang_mete', name: 'Kacang Mete',emoji: '🥜', iconAsset: 'assets/icons/mete.svg'),
        AllergyItem(id: 'almond',      name: 'Almond',     emoji: '🌰', iconAsset: 'assets/icons/almondd.svg'),
        AllergyItem(id: 'ikan',        name: 'Ikan',       emoji: '🐟', iconAsset: 'assets/icons/fish.svg'),
        AllergyItem(id: 'mie',         name: 'Mie',        emoji: '🍜', iconAsset: 'assets/icons/mie.svg'),
      ];
}
