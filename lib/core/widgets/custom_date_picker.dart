import 'package:flutter/material.dart';
import 'package:nepali_utils/nepali_utils.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final bool isBikramSambat;
  final Function(DateTime) onDateSelected;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    this.isBikramSambat = true,
    required this.onDateSelected,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;

  final List<String> _nepaliMonths = [
    'Baisakh',
    'Jestha',
    'Ashadh',
    'Shrawan',
    'Bhadra',
    'Ashwin',
    'Kartik',
    'Mangsir',
    'Poush',
    'Magh',
    'Falgun',
    'Chaitra',
  ];

  final List<String> _englishMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _initializeDate();
  }

  void _initializeDate() {
    if (widget.isBikramSambat) {
      final nepaliDate = widget.initialDate.toNepaliDateTime();
      _selectedDay = nepaliDate.day;
      _selectedMonth = nepaliDate.month;
      _selectedYear = nepaliDate.year;
    } else {
      _selectedDay = widget.initialDate.day;
      _selectedMonth = widget.initialDate.month;
      _selectedYear = widget.initialDate.year;
    }

    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController = FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - (widget.isBikramSambat ? 2070 : 2020),
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int _getDaysInMonth(int year, int month) {
    if (widget.isBikramSambat) {
      try {
        final nepaliDate = NepaliDateTime(year, month, 1);
        return nepaliDate.totalDays;
      } catch (e) {
        return 30;
      }
    } else {
      return DateTime(year, month + 1, 0).day;
    }
  }

  void _onDateChanged() {
    final maxDays = _getDaysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay > maxDays) {
      setState(() {
        _selectedDay = maxDays;
      });
      _dayController.jumpToItem(_selectedDay - 1);
    }
  }

  DateTime _getSelectedDateTime() {
    if (widget.isBikramSambat) {
      final nepaliDate = NepaliDateTime(_selectedYear, _selectedMonth, _selectedDay);
      return nepaliDate.toDateTime();
    } else {
      return DateTime(_selectedYear, _selectedMonth, _selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please select',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Day Picker
                  Expanded(
                    child: _buildScrollWheel(
                      controller: _dayController,
                      itemCount: _getDaysInMonth(_selectedYear, _selectedMonth),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedDay = index + 1;
                        });
                      },
                      itemBuilder: (index) => (index + 1).toString(),
                    ),
                  ),
                  // Month Picker
                  Expanded(
                    flex: 2,
                    child: _buildScrollWheel(
                      controller: _monthController,
                      itemCount: 12,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedMonth = index + 1;
                          _onDateChanged();
                        });
                      },
                      itemBuilder: (index) => widget.isBikramSambat
                          ? _nepaliMonths[index]
                          : _englishMonths[index],
                    ),
                  ),
                  // Year Picker
                  Expanded(
                    child: _buildScrollWheel(
                      controller: _yearController,
                      itemCount: 20,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedYear = (widget.isBikramSambat ? 2070 : 2020) + index;
                          _onDateChanged();
                        });
                      },
                      itemBuilder: (index) =>
                          ((widget.isBikramSambat ? 2070 : 2020) + index).toString(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    final selectedDate = _getSelectedDateTime();
                    widget.onDateSelected(selectedDate);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'SELECT',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required Function(int) onSelectedItemChanged,
    required String Function(int) itemBuilder,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Selection indicator
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[300]!, width: 2),
              bottom: BorderSide(color: Colors.grey[300]!, width: 2),
            ),
          ),
        ),
        // Scrollable list
        ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 50,
          perspective: 0.005,
          diameterRatio: 1.2,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onSelectedItemChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, index) {
              return Center(
                child: Text(
                  itemBuilder(index),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Helper function to show the date picker
Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  bool isBikramSambat = true,
}) async {
  DateTime? selectedDate;

  await showDialog(
    context: context,
    builder: (context) => CustomDatePicker(
      initialDate: initialDate,
      isBikramSambat: isBikramSambat,
      onDateSelected: (date) {
        selectedDate = date;
      },
    ),
  );

  return selectedDate;
}
