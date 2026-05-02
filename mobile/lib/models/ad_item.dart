class AdItem {
  final int id;
  final String title;
  final String? description;
  final String? adType;
  final String? placement;
  final int? relatedContentItemId;
  final String? relatedContentType;
  final String? relatedContentSlug;
  final String? relatedContentTitle;
  final String? imageUrl;
  final String? mobileImageUrl;
  final String? backgroundImageUrl;
  final String? sponsorName;
  final String? sponsorLogoUrl;
  final String? ctaLabel;
  final String? ctaUrl;
  final int priority;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? templateCode;
  final String? templateName;
  final String? templateLayout;
  final String? templateVariant;
  final Map<String, dynamic> templateDefaultConfig;
  final Map<String, dynamic> designConfig;
  final int? titleFontPresetId;
  final String? titleFontCode;
  final String? titleFontKey;
  final String? titleFontName;
  final String? titleFlutterFontFamily;

  const AdItem({
    required this.id,
    required this.title,
    this.description,
    this.adType,
    this.placement,
    this.relatedContentItemId,
    this.relatedContentType,
    this.relatedContentSlug,
    this.relatedContentTitle,
    this.imageUrl,
    this.mobileImageUrl,
    this.backgroundImageUrl,
    this.sponsorName,
    this.sponsorLogoUrl,
    this.ctaLabel,
    this.ctaUrl,
    this.priority = 0,
    this.startsAt,
    this.endsAt,
    this.templateCode,
    this.templateName,
    this.templateLayout,
    this.templateVariant,
    this.templateDefaultConfig = const {},
    this.designConfig = const {},
    this.titleFontPresetId,
    this.titleFontCode,
    this.titleFontKey,
    this.titleFontName,
    this.titleFlutterFontFamily,
  });

  factory AdItem.fromJson(Map<String, dynamic> json) {
    return AdItem(
      id: _asInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      description: _asString(json['description']),
      adType: _asString(json['ad_type']),
      placement: _asString(json['placement']),
      relatedContentItemId: _asInt(json['related_content_item_id']),
      relatedContentType: _asString(json['related_content_type']),
      relatedContentSlug: _asString(json['related_content_slug']),
      relatedContentTitle: _asString(json['related_content_title']),
      imageUrl: _asString(json['image_url']),
      mobileImageUrl: _asString(json['mobile_image_url']),
      backgroundImageUrl: _asString(json['background_image_url']),
      sponsorName: _asString(json['sponsor_name']),
      sponsorLogoUrl: _asString(json['sponsor_logo_url']),
      ctaLabel: _asString(json['cta_label']),
      ctaUrl: _asString(json['cta_url']),
      priority: _asInt(json['priority']) ?? 0,
      startsAt: _asDate(json['starts_at']),
      endsAt: _asDate(json['ends_at']),
      templateCode: _asString(json['template_code']),
      templateName: _asString(json['template_name']),
      templateLayout: _asString(json['template_layout']),
      templateVariant: _asString(json['template_variant']),
      templateDefaultConfig: _asMap(json['template_default_config']),
      designConfig: _asMap(json['design_config']),
      titleFontPresetId: _asInt(json['title_font_preset_id']),
      titleFontCode: _asString(json['title_font_code']),
      titleFontKey: _asString(json['title_font_key']),
      titleFontName: _asString(json['title_font_name']),
      titleFlutterFontFamily: _asString(json['title_flutter_font_family']),
    );
  }

  Map<String, dynamic> get mergedConfig =>
      mergeConfig(templateDefaultConfig, designConfig);

  static Map<String, dynamic> mergeConfig(
    Map<String, dynamic> templateDefaultConfig,
    Map<String, dynamic> designConfig,
  ) {
    return {...templateDefaultConfig, ...designConfig};
  }

  String? get preferredImageUrl {
    for (final url in [mobileImageUrl, imageUrl, backgroundImageUrl]) {
      if (url != null && url.trim().isNotEmpty) return url;
    }
    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    return {};
  }
}
