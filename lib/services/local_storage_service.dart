import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Store and retrieve data from SharedPreferences
class LocalStorageService {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future loadData() async {
    // _names = ["Pushups", "Dips", "Pullups", "Squats"];
    // _descriptions = ["Raised", "Medium bar", "High bar", ""];
    // _valueHistories = getHistoriesMapList([
    //   '{"2022-10-29 00:00:00.000":8, "2022-11-04 00:00:00.000":9, "2022-11-10 00:00:00.000":8, "2022-11-11 00:00:00.000":77}',
    //   '{"2023-10-29 00:00:00.000":2, "2023-10-30 00:00:00.000":2, "2023-10-31 00:00:00.000":3, "2023-11-01 00:00:00.000":4, "2023-11-05 00:00:00.000":4, "2023-11-06 00:00:00.000":5, "2023-11-08 00:00:00.000":6, "2023-11-09 00:00:00.000":7}',
    //   '{"2023-10-21 00:00:00.000":4, "2023-10-22 00:00:00.000":4, "2023-10-24 00:00:00.000":5, "2023-10-25 00:00:00.000":6}',
    //   '{"2023-10-05 00:00:00.000":11, "2023-10-22 00:00:00.000":12, "2023-10-24 00:00:00.000":10}'
    // ]);
    // prefs.setStringList('names', _names);
    // prefs.setStringList('descriptions', _descriptions);
    // prefs.setStringList(
    //     'valueHistories', getHistoriesStringList(_valueHistories));

    final prefs = await _prefs;
    return (
      prefs.getStringList('names') ?? [],
      prefs.getStringList('descriptions') ?? [],
      getHistoriesMapList(prefs.getStringList('valueHistories') ?? [])
    );
  }

  void updateAllPreferences(var names, descriptions, valueHistories) {
    _prefs.then((SharedPreferences prefs) {
      prefs.setStringList('names', names);
      prefs.setStringList('descriptions', descriptions);
      prefs.setStringList('valueHistories', getHistoriesStringList(valueHistories));
    });
  }

  void updateNames(var names) {
    _prefs.then((SharedPreferences prefs) {
      prefs.setStringList('names', names);
    });
  }

  void updateDescriptions(var descriptions) {
    _prefs.then((SharedPreferences prefs) {
      prefs.setStringList('descriptions', descriptions);
    });
  }

  void updateValueHistories(var valueHistories) {
    _prefs.then((SharedPreferences prefs) {
      prefs.setStringList('valueHistories', getHistoriesStringList(valueHistories));
    });
  }

  List<Map<DateTime, int>> getHistoriesMapList(List<String> historiesStringList) {
    List<Map<DateTime, int>> returnList = [];
    for (String historyString in historiesStringList) {
      dynamic historyDict = jsonDecode(historyString);
      Map<DateTime, int> historyMap = {};
      for (String historyDate in historyDict.keys) {
        historyMap[DateTime.parse(historyDate)] = historyDict[historyDate];
      }
      returnList.add(historyMap);
    }
    return returnList;
  }

  List<String> getHistoriesStringList(List<Map<DateTime, int>> historiesMapList) {
    List<String> returnList = [];
    for (Map<DateTime, int> historyMap in historiesMapList) {
      String historyString = jsonEncode(historyMap.map((key, value) => MapEntry(key.toString(), value)));
      returnList.add(historyString);
    }
    return returnList;
  }
}
