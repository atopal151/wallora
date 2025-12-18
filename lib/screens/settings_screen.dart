import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;
  
  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final DatabaseService _databaseService = DatabaseService();
  
  bool _darkMode = false;
  int _gridColumns = 2;
  String _appVersion = '1.0.0';
  int _favoriteCount = 0;
  final Uri _rateAppUri =
      Uri.parse('https://play.google.com/store/apps/details?id=com.lunexo.app.wallora');
  final Uri _feedbackUri = Uri.parse('https://lunexo-dev.godaddysites.com/');
  final Uri _privacyPolicyUri =
      Uri.parse('https://lunexo-dev.godaddysites.com/wallora-privacy');

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
    _loadFavoriteCount();
  }

  /// Ayarları yükler
  Future<void> _loadSettings() async {
    final darkMode = await _settingsService.getDarkMode();
    final gridColumns = await _settingsService.getGridColumns();

    setState(() {
      _darkMode = darkMode;
      _gridColumns = gridColumns;
    });
  }

  /// Uygulama bilgilerini yükler
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      // Hata durumunda varsayılan versiyon kullan
    }
  }

  Future<void> _openFeedback() async {
    final success = await launchUrl(
      _feedbackUri,
      mode: LaunchMode.externalApplication,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open feedback page',
            style: GoogleFonts.inter(fontSize: 13.75),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Favori sayısını yükler
  Future<void> _loadFavoriteCount() async {
    try {
      final favorites = await _databaseService.getAllFavorites();
      setState(() {
        _favoriteCount = favorites.length;
      });
    } catch (e) {
      // Hata durumunda 0 olarak kalır
    }
  }

  Future<void> _openRateApp() async {
    final success = await launchUrl(
      _rateAppUri,
      mode: LaunchMode.externalApplication,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open the store page',
            style: GoogleFonts.inter(fontSize: 13.75),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Favori sayısını günceller (dışarıdan çağrılabilir)
  Future<void> refreshFavoriteCount() async {
    await _loadFavoriteCount();
  }

  Future<void> _openPrivacyPolicy() async {
    final success = await launchUrl(
      _privacyPolicyUri,
      mode: LaunchMode.externalApplication,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open privacy policy',
            style: GoogleFonts.inter(fontSize: 13.75),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          "Settings",
          style: GoogleFonts.pacifico(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 50,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Görünüm Ayarları
          _buildSectionHeader('Appearance'),
          _buildCard([
            _buildSwitchTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: 'Enable dark theme',
              value: _darkMode,
              onChanged: (value) async {
                await _settingsService.setDarkMode(value);
                setState(() {
                  _darkMode = value;
                });
                // Theme değişikliğini uygulamaya yansıt
                if (widget.onThemeChanged != null) {
                  widget.onThemeChanged!();
                }
              },
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.grid_view,
              title: 'Grid Columns',
              subtitle: '$_gridColumns columns',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, size: 20),
                    onPressed: _gridColumns > 2
                        ? () async {
                            final newValue = _gridColumns - 1;
                            await _settingsService.setGridColumns(newValue);
                            setState(() {
                              _gridColumns = newValue;
                            });
                            // Grid columns değiştiğinde callback çağır
                            widget.onThemeChanged?.call();
                          }
                        : null,
                  ),
                  Text(
                    '$_gridColumns',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 20),
                    onPressed: _gridColumns < 4
                        ? () async {
                            final newValue = _gridColumns + 1;
                            await _settingsService.setGridColumns(newValue);
                            setState(() {
                              _gridColumns = newValue;
                            });
                            // Grid columns değiştiğinde callback çağır
                            widget.onThemeChanged?.call();
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // Veri Yönetimi
          _buildSectionHeader('Data Management'),
          _buildCard([
            _buildListTile(
              icon: Icons.favorite,
              title: 'Favorites',
              subtitle: '$_favoriteCount wallpapers saved',
              trailing: Icon(Icons.chevron_right, color: Colors.transparent),
            ),
          ]),

          const SizedBox(height: 16),

          // Hakkında
          _buildSectionHeader('About'),
          _buildCard([
            _buildListTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: 'Version $_appVersion',
              trailing: Icon(Icons.chevron_right, color: Colors.transparent),
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.star_outline,
              title: 'Rate App',
              subtitle: 'Share your feedback',
              trailing: Icon(Icons.chevron_right),
              onTap: _openRateApp,
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Help us improve',
              trailing: Icon(Icons.chevron_right),
              onTap: _openFeedback,
            ),
            _buildDivider(),
            _buildListTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy',
              trailing: Icon(Icons.chevron_right),
              onTap: _openPrivacyPolicy,
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Theme.of(context).iconTheme.color),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.titleMedium?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.black,
        trackOutlineColor: WidgetStateProperty.all(Theme.of(context).scaffoldBackgroundColor),
        trackColor: WidgetStateProperty.all(Theme.of(context).scaffoldBackgroundColor),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: Theme.of(context).iconTheme.color),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.titleMedium?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
      color: Colors.grey[200],
    );
  }
}
