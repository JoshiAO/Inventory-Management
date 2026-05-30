import 'package:flutter/material.dart';

abstract class BaseProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> performTask(Future<void> Function() task) async {
    setLoading(true);
    try {
      await task();
    } finally {
      setLoading(false);
    }
  }
}
