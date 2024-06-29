import 'package:flutter/material.dart';
import 'package:flutter_gmaps/Controllers/MiLinea/lineas_controller.dart';
import 'package:flutter_gmaps/Views/lineas/add_lineas_view.dart';
import 'package:flutter_gmaps/Views/lineas/view_linea_screend.dart';
import 'package:flutter_gmaps/models/MiLinea/lineas_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';


class LineasScreen extends ConsumerStatefulWidget {
  @override
  _LineasScreenState createState() => _LineasScreenState();
}

class _LineasScreenState extends ConsumerState<LineasScreen> {
  String searchQuery = '';
  String filterType = 'Todos';
  String filterSindicato = 'Todos';

  @override
  Widget build(BuildContext context) {
    final lineasAsyncValue = ref.watch(getAllLineasMiniProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Líneas Registradas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: LineasSearchDelegate(ref),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: lineasAsyncValue.when(
        data: (lineas) {
          List<LineasMini> filteredLineas = lineas.where((linea) {
            final matchesSearchQuery = searchQuery.isEmpty ||
                linea.sindicato.toLowerCase().contains(searchQuery.toLowerCase()) ||
                linea.linea.toLowerCase().contains(searchQuery.toLowerCase()) ||
                linea.tipo.toLowerCase().contains(searchQuery.toLowerCase());

            final matchesFilterType = filterType == 'Todos' || linea.tipo == filterType;
            final matchesFilterSindicato = filterSindicato == 'Todos' || linea.sindicato == filterSindicato;

            return matchesSearchQuery && matchesFilterType && matchesFilterSindicato;
          }).toList();

          return ListView.builder(
            itemCount: filteredLineas.length,
            itemBuilder: (context, index) {
              final linea = filteredLineas[index];
              return ListTile(
                title: Text('${linea.sindicato} - ${linea.linea}'),
                subtitle: Text(linea.tipo),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewLineaScreen(linea: linea),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddLineaScreen()),
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrar Líneas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: filterType,
                items: <String>['Todos', 'Tipo1', 'Tipo2', 'Tipo3']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    filterType = value!;
                  });
                },
              ),
              DropdownButton<String>(
                value: filterSindicato,
                items: <String>['Todos', 'Sindicato1', 'Sindicato2', 'Sindicato3']
                    .map((sindicato) => DropdownMenuItem(
                          value: sindicato,
                          child: Text(sindicato),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    filterSindicato = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Aplicar'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}

class LineasSearchDelegate extends SearchDelegate {
  final WidgetRef ref;

  LineasSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final lineasAsyncValue = ref.watch(getAllLineasMiniProvider);

    return lineasAsyncValue.when(
      data: (lineas) {
        List<LineasMini> filteredLineas = lineas.where((linea) {
          return linea.sindicato.toLowerCase().contains(query.toLowerCase()) ||
              linea.linea.toLowerCase().contains(query.toLowerCase()) ||
              linea.tipo.toLowerCase().contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: filteredLineas.length,
          itemBuilder: (context, index) {
            final linea = filteredLineas[index];
            return ListTile(
              title: Text('${linea.sindicato} - ${linea.linea}'),
              subtitle: Text(linea.tipo),
              onTap: () {
                close(context, linea);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: Text('Error: $error')),
    );
  }
}
