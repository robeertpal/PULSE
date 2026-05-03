class FilterOption {
  final int id;
  final String name;

  FilterOption({required this.id, required this.name});

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
