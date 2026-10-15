import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); //Para saber si el cursor esta en la caja

  bool _isFocused = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Escuchamos automáticamente cuándo el usuario toca dentro o fuera de la barra
    _searchFocusNode.addListener(() {
      setState(() {
        _isFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus(); // Quita el foco y devuelve el color de izquierda a derecha
    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Si el usuario toca fuera de la barra, quitamos el foco y el color regresa
      onTap: () => _searchFocusNode.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [

          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxBarWidth = constraints.maxWidth;

                return Container(
                  height: 52,
                  // Recorta las esquinas para que el barrido interior respete los bordes redondeados
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200, // Color base cuando no está pulsada
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      // CAPA 1: El color que entra de derecha a izquierda al tocar la barra
                      Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          width: _isFocused ? maxBarWidth : 0, // De 0 a 100% desde la derecha
                          height: 52,
                          color: Colors.deepPurple, // Cámbialo por Colors.blue si prefieres azul
                        ),
                      ),

                      // CAPA 2: El TextField siempre desplegado encima
                      Center(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: TextStyle(
                            color: _isFocused ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                          cursorColor: Colors.white,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar perfume, marca o nota...',
                            hintStyle: TextStyle(
                              color: _isFocused ? Colors.white70 : Colors.grey.shade600,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: _isFocused ? Colors.white : Colors.deepPurple,
                            ),
                            suffixIcon: (_isFocused || _searchQuery.isNotEmpty)
                                ? IconButton(
                              icon: Icon(
                                Icons.close,
                                color: _isFocused ? Colors.white : Colors.grey.shade700,
                              ),
                              onPressed: _clearSearch,
                            )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Zona inferior temporal (Para comprobar que responde)

          Expanded(
            child: Center(
              child: Text(
                _searchQuery.isEmpty
                    ? 'Toca la barra superior para ver el barrido de color'
                    : 'Buscando: "$_searchQuery"',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}