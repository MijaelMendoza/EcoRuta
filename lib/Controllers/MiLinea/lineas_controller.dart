
import 'package:flutter_gmaps/models/MiLinea/lineas_model.dart';
import 'package:flutter_gmaps/resources/lineas_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lineasMiniApiProvider = Provider<LineasMiniApi>((ref) {
  return LineasMiniApi();
});

final lineasMiniControllerProvider = StateNotifierProvider<LineasMiniController, AsyncValue<List<LineasMini>>>((ref) {
  return LineasMiniController(ref);
});

final getAllLineasMiniProvider = FutureProvider<List<LineasMini>>((ref) async {
  final lineasMiniController = ref.read(lineasMiniControllerProvider.notifier);
  return lineasMiniController.getAllLineasMini();
});

class LineasMiniController extends StateNotifier<AsyncValue<List<LineasMini>>> {
  LineasMiniController(this.ref) : super(const AsyncValue.loading()) {
    fetchLineasMini();
  }

  final Ref ref;

  Future<void> fetchLineasMini() async {
    try {
      final lineasMiniApi = ref.read(lineasMiniApiProvider);
      final lineasMini = await lineasMiniApi.getAllLineasMini();
      state = AsyncValue.data(lineasMini);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addLineasMini(LineasMini lineasMini) async {
    try {
      final lineasMiniApi = ref.read(lineasMiniApiProvider);
      await lineasMiniApi.addLineasMini(lineasMini);
      fetchLineasMini();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateLineasMini(LineasMini lineasMini) async {
    try {
      final lineasMiniApi = ref.read(lineasMiniApiProvider);
      await lineasMiniApi.updateLineasMini(lineasMini);
      fetchLineasMini();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteLineasMini(String lineasMiniId) async {
    try {
      final lineasMiniApi = ref.read(lineasMiniApiProvider);
      await lineasMiniApi.deleteLineasMini(lineasMiniId);
      fetchLineasMini();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<List<LineasMini>> getAllLineasMini() async {
    final lineasMiniApi = ref.read(lineasMiniApiProvider);
    return await lineasMiniApi.getAllLineasMini();
  }
}
