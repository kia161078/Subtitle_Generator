import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  final List<String> historyList;
  final Function(int) onDeleteItem;
  final VoidCallback onClearAll;

  const HistoryScreen({
    super.key,
    required this.historyList,
    required this.onDeleteItem,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (historyList.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onClearAll,
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  label: const Text(
                    'Clear History',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: historyList.isEmpty
              ? const Center(
                  child: Text(
                    'No subtitles generated yet!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: const Color.fromARGB(255, 52, 42, 96),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file, color: Color(0xFF00F0FF)),
                        title: Text(
                          historyList[index],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Saved in Download folder',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white70),
                          onPressed: () => onDeleteItem(index),
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