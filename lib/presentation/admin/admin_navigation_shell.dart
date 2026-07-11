import 'package:flutter/material.dart';

import 'admin_portal_components.dart';
import 'admin_portal_texts.dart';

class AdminNavigationShell extends StatelessWidget {
  const AdminNavigationShell({
    super.key,
    required this.texts,
    required this.userInfo,
    required this.currentRoute,
    required this.pageTitle,
    required this.onLogout,
    required this.onRefresh,
    required this.refreshing,
    required this.loggingOut,
    required this.child,
  });

  final AdminPortalTexts texts;
  final AdminPortalUserInfo userInfo;
  final String currentRoute;
  final String pageTitle;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;
  final bool refreshing;
  final bool loggingOut;
  final Widget child;

  static const double sidebarWidth = 252;
  static const double compactBreakpoint = 900;
  static const double maxContentWidth = 1280;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < compactBreakpoint;
        final Widget sidebar = _AdminNavigationSidebar(
          texts: texts,
          userInfo: userInfo,
          currentRoute: currentRoute,
          onLogout: onLogout,
          loggingOut: loggingOut,
        );

        if (compact) {
          return Scaffold(
            backgroundColor: AdminPalette.background,
            drawer: Drawer(width: sidebarWidth, child: sidebar),
            body: Builder(
              builder: (BuildContext scaffoldContext) => _AdminNavigationMainArea(
                texts: texts,
                compact: true,
                pageTitle: pageTitle,
                refreshing: refreshing,
                loggingOut: loggingOut,
                onOpenMenu: () => Scaffold.of(scaffoldContext).openDrawer(),
                onRefresh: onRefresh,
                onLogout: onLogout,
                child: child,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AdminPalette.background,
          body: Row(
            children: <Widget>[
              SizedBox(width: sidebarWidth, child: sidebar),
              Expanded(
                child: _AdminNavigationMainArea(
                  texts: texts,
                  compact: false,
                  pageTitle: pageTitle,
                  refreshing: refreshing,
                  loggingOut: loggingOut,
                  onRefresh: onRefresh,
                  onLogout: onLogout,
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminNavigationMainArea extends StatelessWidget {
  const _AdminNavigationMainArea({
    required this.texts,
    required this.compact,
    required this.pageTitle,
    required this.refreshing,
    required this.loggingOut,
    required this.onRefresh,
    required this.onLogout,
    required this.child,
    this.onOpenMenu,
  });

  final AdminPortalTexts texts;
  final bool compact;
  final String pageTitle;
  final bool refreshing;
  final bool loggingOut;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final VoidCallback? onOpenMenu;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: <Widget>[
          Container(
            height: 72,
            padding: EdgeInsets.symmetric(horizontal: compact ? AdminSpacing.lg : AdminSpacing.xl),
            decoration: const BoxDecoration(
              color: AdminPalette.background,
              border: Border(bottom: BorderSide(color: AdminPalette.border)),
            ),
            child: Row(
              children: <Widget>[
                if (compact) ...<Widget>[
                  IconButton(
                    tooltip: texts.menu,
                    onPressed: onOpenMenu,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        pageTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AdminPalette.dark,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AdminPalette.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              texts.online,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AdminPalette.mutedText,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: texts.refresh,
                  onPressed: refreshing ? null : onRefresh,
                  icon: refreshing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh_rounded),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: texts.logout,
                  onPressed: loggingOut ? null : onLogout,
                  icon: loggingOut
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.logout_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? AdminSpacing.lg : AdminSpacing.xl,
                AdminSpacing.lg,
                compact ? AdminSpacing.lg : AdminSpacing.xl,
                AdminSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AdminNavigationShell.maxContentWidth,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNavigationSidebar extends StatelessWidget {
  const _AdminNavigationSidebar({
    required this.texts,
    required this.userInfo,
    required this.currentRoute,
    required this.onLogout,
    required this.loggingOut,
  });

  final AdminPortalTexts texts;
  final AdminPortalUserInfo userInfo;
  final String currentRoute;
  final VoidCallback onLogout;
  final bool loggingOut;

  @override
  Widget build(BuildContext context) {
    final _AdminNavigationTexts navigationTexts = _AdminNavigationTexts.of(context);
    final String displayName = _firstNotEmpty(userInfo.name, texts.userFallback);
    final String displayEmail = _firstNotEmpty(userInfo.email, texts.userRole);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AdminPalette.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AdminPalette.dark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '6',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Six',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark),
                        ),
                        Text(
                          texts.portalTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminPalette.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              AdminNavItem(
                icon: Icons.dashboard_rounded,
                label: texts.dashboard,
                selected: currentRoute == '/admin/dashboard',
                onTap: () => _navigate(context, '/admin/dashboard'),
              ),
              const SizedBox(height: 6),
              AdminNavItem(
                icon: Icons.lightbulb_rounded,
                label: navigationTexts.newIdeas,
                selected: currentRoute == '/admin/novas-ideias',
                onTap: () => _navigate(context, '/admin/novas-ideias'),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminPalette.softSurface,
                  borderRadius: BorderRadius.circular(AdminRadius.lg),
                  border: Border.all(color: AdminPalette.border),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AdminPalette.dark,
                      child: Text(
                        _initials(displayName),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AdminPalette.dark),
                          ),
                          Text(
                            displayEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AdminPalette.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: loggingOut ? null : onLogout,
                icon: loggingOut
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.logout_rounded, size: 18),
                label: Text(texts.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    if (currentRoute == route) {
      if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
        Navigator.of(context).pop();
      }
      return;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  String _firstNotEmpty(String? first, String fallback) {
    final String normalized = first?.trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }

  String _initials(String value) {
    final List<String> parts = value.trim().split(RegExp(r'\s+')).where((String part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
  }
}

class _AdminNavigationTexts {
  const _AdminNavigationTexts({required this.newIdeas});

  final String newIdeas;

  factory _AdminNavigationTexts.of(BuildContext context) {
    final String language = Localizations.localeOf(context).languageCode;
    if (language == 'en') return const _AdminNavigationTexts(newIdeas: 'New ideas');
    if (language == 'es') return const _AdminNavigationTexts(newIdeas: 'Nuevas ideas');
    return const _AdminNavigationTexts(newIdeas: 'Novas ideias');
  }
}
