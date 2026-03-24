import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class StacksProvider extends ChangeNotifier {
  final _api = ApiService();

  List<dynamic> _stacks = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get stacks => _stacks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchStacks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _stacks = await _api.listStacks();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> createStack(Map<String, dynamic> data) async {
    try {
      final stack = await _api.createStack(data);
      _stacks = [stack, ..._stacks];
      notifyListeners();
      return stack;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteStack(int id) async {
    try {
      await _api.deleteStack(id);
      _stacks = _stacks.where((s) => s['id'] != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deployStack(int id) async {
    try {
      await _api.deployStack(id);
      // Refresh single stack status
      await refreshStack(id);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> stackAction(int id, String action) async {
    try {
      await _api.stackAction(id, action);
      await refreshStack(id);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String> fetchLogs(int id) async {
    try {
      return await _api.stackLogs(id);
    } catch (e) {
      return '';
    }
  }

  Future<bool> updateEnv(int id, Map<String, String> envVars) async {
    try {
      final updated = await _api.updateStackEnv(id, envVars);
      _updateLocal(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshStack(int id) async {
    try {
      final updated = await _api.getStack(id);
      _updateLocal(updated);
      notifyListeners();
    } catch (_) {}
  }

  void _updateLocal(Map<String, dynamic> updated) {
    final idx = _stacks.indexWhere((s) => s['id'] == updated['id']);
    if (idx != -1) {
      _stacks = List.from(_stacks)..[idx] = updated;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
