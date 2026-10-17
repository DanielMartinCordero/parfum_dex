import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxBarWidth = constraints.maxWidth;

          return Container(
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              children: [
                // CAPA 1: el color que entra de derecha a izquierda
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    width: isFocused ? maxBarWidth : 0,
                    height: 52,
                    color: Colors.deepPurple,
                  ),
                ),

                // CAPA 2: el TextField encima
                Center(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: TextStyle(
                      color: isFocused ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                    cursorColor: Colors.white,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      hintText: 'Buscar perfume, marca o nota...',
                      hintStyle: TextStyle(
                        color: isFocused
                            ? Colors.white70
                            : Colors.grey.shade600,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isFocused ? Colors.white : Colors.deepPurple,
                      ),
                      suffixIcon: (isFocused || searchQuery.isNotEmpty)
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                color: isFocused
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                              onPressed: onClear,
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
    );
  }
}
