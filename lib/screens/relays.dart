import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../util/messages_options.dart';
import '../util/messages_localizations.dart';

class RelaysTable extends StatefulWidget {
  const RelaysTable({super.key});

  @override
  State<RelaysTable> createState() => _RelaysTableState();
}

class _RestorableRelaySelections extends RestorableProperty<Set<int>> {
  Set<int> _relaySelections = {};

  /// Returns whether or not a relay row is selected by index.
  bool isSelected(int index) => _relaySelections.contains(index);

  /// Takes a list of [_Relay]s and saves the row indices of selected rows
  /// into a [Set].
  void setRelaySelections(List<_Relay> relays) {
    final updatedSet = <int>{};
    for (var i = 0; i < relays.length; i += 1) {
      var relay = relays[i];
      if (relay.selected) {
        updatedSet.add(i);
      }
    }
    _relaySelections = updatedSet;
    notifyListeners();
  }

  @override
  Set<int> createDefaultValue() => _relaySelections;

  @override
  Set<int> fromPrimitives(Object? data) {
    final selectedItemIndices = data as List<dynamic>;
    _relaySelections = {
      ...selectedItemIndices.map<int>((dynamic id) => id as int),
    };
    return _relaySelections;
  }

  @override
  void initWithValue(Set<int> value) {
    _relaySelections = value;
  }

  @override
  Object toPrimitives() => _relaySelections.toList();
}

class _RelaysTableState extends State<RelaysTable> with RestorationMixin {
  final _RestorableRelaySelections _relaySelections =
      _RestorableRelaySelections();
  final RestorableInt _rowIndex = RestorableInt(0);
  final RestorableInt _rowsPerPage =
      RestorableInt(PaginatedDataTable.defaultRowsPerPage);
  final RestorableBool _sortAscending = RestorableBool(true);
  final RestorableIntN _sortColumnIndex = RestorableIntN(null);
  _RelayDataSource? _relaysDataSource;

  @override
  String get restorationId => 'data_table_demo';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_relaySelections, 'selected_row_indices');
    registerForRestoration(_rowIndex, 'current_row_index');
    registerForRestoration(_rowsPerPage, 'rows_per_page');
    registerForRestoration(_sortAscending, 'sort_ascending');
    registerForRestoration(_sortColumnIndex, 'sort_column_index');

    _relaysDataSource ??= _RelayDataSource(context);
    switch (_sortColumnIndex.value) {
      case 0:
        _relaysDataSource!._sort<String>((d) => d.name, _sortAscending.value);
        break;
      case 1:
        _relaysDataSource!
            ._sort<num>((d) => d.calories, _sortAscending.value);
        break;
      case 2:
        _relaysDataSource!._sort<num>((d) => d.fat, _sortAscending.value);
        break;
      case 3:
        _relaysDataSource!._sort<num>((d) => d.carbs, _sortAscending.value);
        break;
      case 4:
        _relaysDataSource!._sort<num>((d) => d.protein, _sortAscending.value);
        break;
      case 5:
        _relaysDataSource!._sort<num>((d) => d.sodium, _sortAscending.value);
        break;
      case 6:
        _relaysDataSource!._sort<num>((d) => d.calcium, _sortAscending.value);
        break;
      case 7:
        _relaysDataSource!._sort<num>((d) => d.iron, _sortAscending.value);
        break;
    }
    _relaysDataSource!.updateSelectedRelays(_relaySelections);
    _relaysDataSource!.addListener(_updateSelectedRelayRowListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _relaysDataSource ??= _RelayDataSource(context);
    _relaysDataSource!.addListener(_updateSelectedRelayRowListener);
  }

  void _updateSelectedRelayRowListener() {
    _relaySelections.setRelaySelections(_relaysDataSource!._relays);
  }

  void _sort<T>(
    Comparable<T> Function(_Relay d) getField,
    int columnIndex,
    bool ascending,
  ) {
    _relaysDataSource!._sort<T>(getField, ascending);
    setState(() {
      _sortColumnIndex.value = columnIndex;
      _sortAscending.value = ascending;
    });
  }

  @override
  void dispose() {
    _rowsPerPage.dispose();
    _sortColumnIndex.dispose();
    _sortAscending.dispose();
    _relaysDataSource!.removeListener(_updateSelectedRelayRowListener);
    _relaysDataSource!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MessagesLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(localizations.demoDataTableTitle),
      ),
      body: Scrollbar(
        child: ListView(
          restorationId: 'data_table_list_view',
          padding: const EdgeInsets.all(16),
          children: [
            PaginatedDataTable(
              header: Text(localizations.dataTableHeader),
              rowsPerPage: _rowsPerPage.value,
              onRowsPerPageChanged: (value) {
                setState(() {
                  _rowsPerPage.value = value!;
                });
              },
              initialFirstRowIndex: _rowIndex.value,
              onPageChanged: (rowIndex) {
                setState(() {
                  _rowIndex.value = rowIndex;
                });
              },
              sortColumnIndex: _sortColumnIndex.value,
              sortAscending: _sortAscending.value,
              onSelectAll: _relaysDataSource!._selectAll,
              columns: [
                DataColumn(
                  label: Text(localizations.dataTableColumnDessert),
                  onSort: (columnIndex, ascending) =>
                      _sort<String>((d) => d.name, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text(localizations.dataTableColumnCalories),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<num>((d) => d.calories, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text(localizations.dataTableColumnFat),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<num>((d) => d.fat, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text(localizations.dataTableColumnCarbs),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<num>((d) => d.carbs, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text(localizations.dataTableColumnProtein),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<num>((d) => d.protein, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text(localizations.dataTableColumnSodium),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<num>((d) => d.sodium, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text(localizations.dataTableColumnCalcium),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<num>((d) => d.calcium, columnIndex, ascending),
                ),
                DataColumn(
                  label: Text(localizations.dataTableColumnIron),
                  numeric: true,
                  onSort: (columnIndex, ascending) =>
                      _sort<num>((d) => d.iron, columnIndex, ascending),
                ),
              ],
              source: _relaysDataSource!,
            ),
          ],
        ),
      ),
    );
  }
}

class _Relay {
  _Relay(
    this.name,
    this.calories,
    this.fat,
    this.carbs,
    this.protein,
    this.sodium,
    this.calcium,
    this.iron,
  );

  final String name;
  final int calories;
  final double fat;
  final int carbs;
  final double protein;
  final int sodium;
  final int calcium;
  final int iron;
  bool selected = false;
}

class _RelayDataSource extends DataTableSource {
  _RelayDataSource(this.context) {
    final localizations = MessagesLocalizations.of(context)!;
    _relays = <_Relay>[
      _Relay(
        localizations.dataTableRowFrozenYogurt,
        159,
        6.0,
        24,
        4.0,
        87,
        14,
        1,
      ),
      _Relay(
        localizations.dataTableRowIceCreamSandwich,
        237,
        9.0,
        37,
        4.3,
        129,
        8,
        1,
      ),
      _Relay(
        localizations.dataTableRowEclair,
        262,
        16.0,
        24,
        6.0,
        337,
        6,
        7,
      ),
      _Relay(
        localizations.dataTableRowCupcake,
        305,
        3.7,
        67,
        4.3,
        413,
        3,
        8,
      ),
      _Relay(
        localizations.dataTableRowGingerbread,
        356,
        16.0,
        49,
        3.9,
        327,
        7,
        16,
      ),
      _Relay(
        localizations.dataTableRowJellyBean,
        375,
        0.0,
        94,
        0.0,
        50,
        0,
        0,
      ),
      _Relay(
        localizations.dataTableRowLollipop,
        392,
        0.2,
        98,
        0.0,
        38,
        0,
        2,
      ),
      _Relay(
        localizations.dataTableRowHoneycomb,
        408,
        3.2,
        87,
        6.5,
        562,
        0,
        45,
      ),
      _Relay(
        localizations.dataTableRowDonut,
        452,
        25.0,
        51,
        4.9,
        326,
        2,
        22,
      ),
      _Relay(
        localizations.dataTableRowApplePie,
        518,
        26.0,
        65,
        7.0,
        54,
        12,
        6,
      ),
      _Relay(
        localizations.dataTableRowWithSugar(
          localizations.dataTableRowFrozenYogurt,
        ),
        168,
        6.0,
        26,
        4.0,
        87,
        14,
        1,
      ),
      _Relay(
        localizations.dataTableRowWithSugar(
          localizations.dataTableRowIceCreamSandwich,
        ),
        246,
        9.0,
        39,
        4.3,
        129,
        8,
        1,
      ),
      _Relay(
        localizations.dataTableRowWithSugar(
          localizations.dataTableRowEclair,
        ),
        271,
        16.0,
        26,
        6.0,
        337,
        6,
        7,
      ),
      _Relay(
        localizations.dataTableRowWithSugar(
          localizations.dataTableRowCupcake,
        ),
        314,
        3.7,
        69,
        4.3,
        413,
        3,
        8,
      ),
      _Relay(
        localizations.dataTableRowWithSugar(
          localizations.dataTableRowGingerbread,
        ),
        345,
        16.0,
        51,
        3.9,
        327,
        7,
        16,
      ),
      _Relay(
        localizations.dataTableRowWithSugar(
          localizations.dataTableRowJellyBean,
        ),
        364,
        0.0,
        96,
        0.0,
        50,
        0,
        0,
      ),
      _Relay(
        localizations.dataTableRowWithSugar(
          localizations.dataTableRowLollipop,
        ),
        401,
        0.2,
        100,
        0.0,
        38,
        0,
        2,
      ),
      _Relay(
        localizations.dataTableRowWithSugar(
          localizations.dataTableRowHoneycomb,
        ),
        417,
        3.2,
        89,
        6.5,
        562,
        0,
        45,
      ),
      _Relay(
        localizations.dataTableRowWithSugar(
          localizations.dataTableRowDonut,
        ),
        461,
        25.0,
        53,
        4.9,
        326,
        2,
        22,
      ),
      _Relay(
        localizations.dataTableRowWithSugar(
          localizations.dataTableRowApplePie,
        ),
        527,
        26.0,
        67,
        7.0,
        54,
        12,
        6,
      ),
      _Relay(
        localizations.dataTableRowWithHoney(
          localizations.dataTableRowFrozenYogurt,
        ),
        223,
        6.0,
        36,
        4.0,
        87,
        14,
        1,
      ),
      _Relay(
        localizations.dataTableRowWithHoney(
          localizations.dataTableRowIceCreamSandwich,
        ),
        301,
        9.0,
        49,
        4.3,
        129,
        8,
        1,
      ),
      _Relay(
        localizations.dataTableRowWithHoney(
          localizations.dataTableRowEclair,
        ),
        326,
        16.0,
        36,
        6.0,
        337,
        6,
        7,
      ),
      _Relay(
        localizations.dataTableRowWithHoney(
          localizations.dataTableRowCupcake,
        ),
        369,
        3.7,
        79,
        4.3,
        413,
        3,
        8,
      ),
      _Relay(
        localizations.dataTableRowWithHoney(
          localizations.dataTableRowGingerbread,
        ),
        420,
        16.0,
        61,
        3.9,
        327,
        7,
        16,
      ),
      _Relay(
        localizations.dataTableRowWithHoney(
          localizations.dataTableRowJellyBean,
        ),
        439,
        0.0,
        106,
        0.0,
        50,
        0,
        0,
      ),
      _Relay(
        localizations.dataTableRowWithHoney(
          localizations.dataTableRowLollipop,
        ),
        456,
        0.2,
        110,
        0.0,
        38,
        0,
        2,
      ),
      _Relay(
        localizations.dataTableRowWithHoney(
          localizations.dataTableRowHoneycomb,
        ),
        472,
        3.2,
        99,
        6.5,
        562,
        0,
        45,
      ),
      _Relay(
        localizations.dataTableRowWithHoney(
          localizations.dataTableRowDonut,
        ),
        516,
        25.0,
        63,
        4.9,
        326,
        2,
        22,
      ),
      _Relay(
        localizations.dataTableRowWithHoney(
          localizations.dataTableRowApplePie,
        ),
        582,
        26.0,
        77,
        7.0,
        54,
        12,
        6,
      ),
    ];
  }

  final BuildContext context;
  late List<_Relay> _relays;

  void _sort<T>(Comparable<T> Function(_Relay d) getField, bool ascending) {
    _relays.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });
    notifyListeners();
  }

  int _selectedCount = 0;

  void updateSelectedRelays(_RestorableRelaySelections selectedRows) {
    _selectedCount = 0;
    for (var i = 0; i < _relays.length; i += 1) {
      var relay = _relays[i];
      if (selectedRows.isSelected(i)) {
        relay.selected = true;
        _selectedCount += 1;
      } else {
        relay.selected = false;
      }
    }
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    final format = NumberFormat.decimalPercentPattern(
      locale: MessagesOptions.of(context).locale.toString(),
      decimalDigits: 0,
    );
    assert(index >= 0);
    if (index >= _relays.length) return null;
    final relay = _relays[index];
    return DataRow.byIndex(
      index: index,
      selected: relay.selected,
      onSelectChanged: (value) {
        if (relay.selected != value) {
          _selectedCount += value! ? 1 : -1;
          assert(_selectedCount >= 0);
          relay.selected = value;
          notifyListeners();
        }
      },
      cells: [
        DataCell(Text(relay.name)),
        DataCell(Text('${relay.calories}')),
        DataCell(Text(relay.fat.toStringAsFixed(1))),
        DataCell(Text('${relay.carbs}')),
        DataCell(Text(relay.protein.toStringAsFixed(1))),
        DataCell(Text('${relay.sodium}')),
        DataCell(Text(format.format(relay.calcium / 100))),
        DataCell(Text(format.format(relay.iron / 100))),
      ],
    );
  }

  @override
  int get rowCount => _relays.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => _selectedCount;

  void _selectAll(bool? checked) {
    for (final relay in _relays) {
      relay.selected = checked ?? false;
    }
    _selectedCount = checked! ? _relays.length : 0;
    notifyListeners();
  }
}



