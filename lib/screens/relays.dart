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
  String get restorationId => 'relays_table';

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
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back,color: Colors.black,),
                ),
                SizedBox(width: 12,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Relays',
                        style: TextStyle( fontSize: 16 ,fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.settings,color: Colors.black54,),
              ],
            ),
          ),
        ),
      ),
    body: ListView(
        restorationId: 'data_table_list_view',
        children: [
          PaginatedDataTable(
            //header: Text('Relays'),
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
                label: Text('Address'),
                onSort: (columnIndex, ascending) =>
                    _sort<String>((d) => d.name, columnIndex, ascending),
              ),
              DataColumn(
                label: Text('Write'),
                numeric: true,
                onSort: (columnIndex, ascending) =>
                    _sort<num>((d) => d.calories, columnIndex, ascending),
              ),
              DataColumn(
                label: Text('Read'),
                numeric: true,
                onSort: (columnIndex, ascending) =>
                    _sort<num>((d) => d.fat, columnIndex, ascending),
              ),
            ],
            source: _relaysDataSource!,
          ),
          SizedBox(width: 15,),
          Expanded(
            child: TextField(
              //focusNode: focusNode,
              //controller: textEntryField,
              decoration: InputDecoration(
                hintText: "New Relay...",
                hintStyle: TextStyle(color: Colors.black54),
                border: InputBorder.none,
              ),
              onSubmitted: (String value) {
                //sendMessage(value);
                //textEntryField.clear();
                //focusNode.requestFocus();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Relay {
  _Relay(
    this.name,
    this.calories,
    this.fat,
  );

  final String name;
  final int calories;
  final int fat;
  bool selected = false;
}

class _RelayDataSource extends DataTableSource {
  // TODO: Comes from db
  _RelayDataSource(this.context) {
    final localizations = MessagesLocalizations.of(context)!;
    _relays = <_Relay>[
      _Relay(
        'ws://192.168.50.144:8081',
        159,
        6,
      ),
      _Relay(
        'wss://192.168.50.162:6969',
        237,
        9,
      ),
      _Relay(
        'wss://nostr.lol',
        262,
        16,
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
      //locale: MessagesOptions.of(context).locale.toString(), // FIXME
      locale: 'en',
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
