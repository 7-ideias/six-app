import 'package:flutter/material.dart';

class DateSelectorMobileBottomSheet extends StatefulWidget {
  const DateSelectorMobileBottomSheet({
    super.key,
    required this.title,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.applyButtonLabel = 'Aplicar data',
  });

  final String title;
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String applyButtonLabel;

  @override
  State<DateSelectorMobileBottomSheet> createState() =>
      _DateSelectorMobileBottomSheetState();
}

class _DateSelectorMobileBottomSheetState
    extends State<DateSelectorMobileBottomSheet> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Colors.white;
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  DateTime get _today => _startOfDay(DateTime.now());
  DateTime get _firstDate => _startOfDay(widget.firstDate);
  DateTime get _lastDate => _startOfDay(widget.lastDate);

  @override
  void initState() {
    super.initState();
    _selectedDate = _clampDate(_startOfDay(widget.initialDate));
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 10),
                _handle(),
                const SizedBox(height: 16),
                _header(context),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    children: <Widget>[
                      _selectedSummary(),
                      const SizedBox(height: 14),
                      _quickShortcuts(),
                      const SizedBox(height: 14),
                      _calendarCard(),
                    ],
                  ),
                ),
                _footer(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _handle() {
    return Container(
      width: 42,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.event_available_outlined, color: _primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _titleTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Escolha uma data sem sair do atendimento.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _mutedTextColor,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _selectedSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, Color(0xFF123B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1F0B1F3A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _formatDate(_selectedDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _weekdayName(_selectedDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD7E3F5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickShortcuts() {
    final List<_DateShortcut> shortcuts = <_DateShortcut>[
      _DateShortcut('Hoje', _today),
      _DateShortcut('Amanhã', _today.add(const Duration(days: 1))),
      _DateShortcut('Em 7 dias', _today.add(const Duration(days: 7))),
      _DateShortcut('Em 15 dias', _today.add(const Duration(days: 15))),
      _DateShortcut('Em 30 dias', _today.add(const Duration(days: 30))),
    ].where((shortcut) => _isAllowed(shortcut.date)).toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Atalhos rápidos',
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: shortcuts.map((shortcut) {
              final bool selected = _isSameDay(shortcut.date, _selectedDate);
              return ChoiceChip(
                selected: selected,
                label: Text(shortcut.label),
                onSelected: (_) => _selectDate(shortcut.date),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _primaryColor,
                  fontWeight: FontWeight.w800,
                ),
                selectedColor: _accentColor,
                backgroundColor: const Color(0xFFF8FAFC),
                side: BorderSide(
                  color: selected ? _accentColor : _borderColor,
                ),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _calendarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: <Widget>[
          _monthHeader(),
          const SizedBox(height: 12),
          _weekdayHeader(),
          const SizedBox(height: 8),
          _monthGrid(),
        ],
      ),
    );
  }

  Widget _monthHeader() {
    final bool canGoPrevious = _canChangeMonth(-1);
    final bool canGoNext = _canChangeMonth(1);

    return Row(
      children: <Widget>[
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: canGoPrevious ? () => _changeMonth(-1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            '${_monthName(_visibleMonth.month)} de ${_visibleMonth.year}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _titleTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: canGoNext ? () => _changeMonth(1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _weekdayHeader() {
    const List<String> weekdays = <String>['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return Row(
      children: weekdays.map((String day) {
        return Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _mutedTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _monthGrid() {
    final DateTime firstDay = DateTime(_visibleMonth.year, _visibleMonth.month);
    final int leadingEmptyCells = firstDay.weekday % DateTime.daysPerWeek;
    final int daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final int totalCells = leadingEmptyCells + daysInMonth;
    final int rows = (totalCells / DateTime.daysPerWeek).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows * DateTime.daysPerWeek,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: DateTime.daysPerWeek,
        mainAxisExtent: 40,
        crossAxisSpacing: 5,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (BuildContext context, int index) {
        final int dayNumber = index - leadingEmptyCells + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final DateTime date = DateTime(
          _visibleMonth.year,
          _visibleMonth.month,
          dayNumber,
        );
        return _DayCell(
          date: date,
          selected: _isSameDay(date, _selectedDate),
          today: _isSameDay(date, _today),
          enabled: _isAllowed(date),
          onTap: () => _selectDate(date),
        );
      },
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_selectedDate),
              child: Text(widget.applyButtonLabel),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate(DateTime date) {
    if (!_isAllowed(date)) {
      return;
    }

    setState(() {
      _selectedDate = _startOfDay(date);
      _visibleMonth = DateTime(date.year, date.month);
    });
  }

  bool _canChangeMonth(int offset) {
    final DateTime targetMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    final DateTime firstMonth = DateTime(_firstDate.year, _firstDate.month);
    final DateTime lastMonth = DateTime(_lastDate.year, _lastDate.month);
    return !targetMonth.isBefore(firstMonth) && !targetMonth.isAfter(lastMonth);
  }

  void _changeMonth(int offset) {
    if (!_canChangeMonth(offset)) {
      return;
    }
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
    });
  }

  bool _isAllowed(DateTime date) {
    final DateTime normalized = _startOfDay(date);
    return !normalized.isBefore(_firstDate) && !normalized.isAfter(_lastDate);
  }

  DateTime _clampDate(DateTime date) {
    if (date.isBefore(_firstDate)) {
      return _firstDate;
    }
    if (date.isAfter(_lastDate)) {
      return _lastDate;
    }
    return date;
  }

  static DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static String _formatDate(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String _weekdayName(DateTime value) {
    const List<String> weekdays = <String>[
      'segunda-feira',
      'terça-feira',
      'quarta-feira',
      'quinta-feira',
      'sexta-feira',
      'sábado',
      'domingo',
    ];
    return weekdays[value.weekday - 1];
  }

  static String _monthName(int month) {
    const List<String> months = <String>[
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return months[month - 1];
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.selected,
    required this.today,
    required this.enabled,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _accentColor = Color(0xFF2563EB);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final DateTime date;
  final bool selected;
  final bool today;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = !enabled
        ? _mutedTextColor.withValues(alpha: 0.38)
        : selected
            ? Colors.white
            : _primaryColor;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? _accentColor
                  : today
                      ? _accentColor.withValues(alpha: 0.42)
                      : _borderColor.withValues(alpha: enabled ? 1 : 0),
            ),
          ),
          child: Text(
            date.day.toString(),
            style: TextStyle(
              color: foregroundColor,
              fontWeight: selected || today ? FontWeight.w900 : FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateShortcut {
  const _DateShortcut(this.label, this.date);

  final String label;
  final DateTime date;
}
