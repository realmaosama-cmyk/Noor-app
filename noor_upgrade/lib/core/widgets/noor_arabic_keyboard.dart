import 'package:flutter/material.dart';

/// In-app Arabic keyboard used for child profile names.
class NoorArabicKeyboard extends StatefulWidget {
  const NoorArabicKeyboard({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<NoorArabicKeyboard> createState() => _NoorArabicKeyboardState();
}

class _NoorArabicKeyboardState extends State<NoorArabicKeyboard> {
  static const _rows = <List<String>>[
    ['ض', 'ص', 'ث', 'ق', 'ف', 'غ', 'ع', 'ه', 'خ', 'ح'],
    ['ج', 'د', 'ش', 'س', 'ي', 'ب', 'ل', 'ا', 'ت', 'ن'],
    ['م', 'ك', 'ة', 'ى', 'و', 'ز', 'ظ', 'ذ', 'ء', 'ئ', 'ؤ', 'ر'],
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant NoorArabicKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _insert(String value) {
    final current = widget.controller.value;
    final selection = current.selection;
    final start = selection.isValid ? selection.start : current.text.length;
    final end = selection.isValid ? selection.end : current.text.length;
    final text = current.text.replaceRange(start, end, value);
    final cursor = start + value.length;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  void _backspace() {
    final current = widget.controller.value;
    final selection = current.selection;
    final start = selection.isValid ? selection.start : current.text.length;
    final end = selection.isValid ? selection.end : current.text.length;
    if (start == 0 && end == 0) return;
    final deleteStart = start == end ? start - 1 : start;
    final text = current.text.replaceRange(deleteStart, end, '');
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: deleteStart),
    );
  }

  Widget _key(String label, {VoidCallback? onTap, bool wide = false}) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      flex: wide ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: onTap,
            child: SizedBox(
              height: 48,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: wide ? 14 : 20,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          12 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Material(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.keyboard_alt_rounded),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'اكتب اسم الطفل',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      tooltip: 'إغلاق لوحة المفاتيح',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.keyboard_hide_rounded),
                    ),
                  ],
                ),
                TextField(
                  controller: widget.controller,
                  readOnly: true,
                  showCursor: false,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'الاسم يظهر هنا',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final row in _rows)
                  Row(
                    children: [
                      for (final letter in row)
                        _key(letter, onTap: () => _insert(letter)),
                    ],
                  ),
                Row(
                  children: [
                    _key('مسافة', wide: true, onTap: () => _insert(' ')),
                    _key('حذف', wide: true, onTap: _backspace),
                    _key('مسح', wide: true, onTap: widget.controller.clear),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('تم'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
