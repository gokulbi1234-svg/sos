import 'package:flutter/material.dart';
import '../models/sos_history_model.dart';

class HistoryScreen extends StatefulWidget {
  final List<SOSHistory> historyList;
final Function saveHistory;

  const HistoryScreen({
  super.key,
  required this.historyList,
  required this.saveHistory,
});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  Set<int> selectedItems = {};
  bool isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSelectionMode
              ? "${selectedItems.length} selected"
              : "Emergency Activity Log",
        ),
        backgroundColor: Colors.pink,
        actions: [

          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
          onPressed: () {

  setState(() {
    widget.historyList.removeWhere(
      (item) => selectedItems.contains(
        widget.historyList.indexOf(item),
      ),
    );

    selectedItems.clear();
    isSelectionMode = false;
  });

  // 🔹 Save updated history
  widget.saveHistory(); 

},
            ),
        ],
      ),

      body: widget.historyList.isEmpty
          ? const Center(child: Text("No SOS activity yet"))
          : ListView.builder(
              itemCount: widget.historyList.length,
              itemBuilder: (context, index) {

                final item = widget.historyList[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
  leading: isSelectionMode
      ? Checkbox(
          value: selectedItems.contains(index),
          onChanged: (value) {
            setState(() {

              if (selectedItems.contains(index)) {
                selectedItems.remove(index);
              } else {
                selectedItems.add(index);
              }

              if (selectedItems.isEmpty) {
                isSelectionMode = false;
              }

            });
          },
        )
      : null,

  title: Text(item.action),
subtitle: Text("${item.location}\n${item.time}"),

  onLongPress: () {
    setState(() {
      isSelectionMode = true;
      selectedItems.add(index);
    });
  },

  onTap: () {
    if (isSelectionMode) {

      setState(() {

        if (selectedItems.contains(index)) {
          selectedItems.remove(index);
        } else {
          selectedItems.add(index);
        }

        if (selectedItems.isEmpty) {
          isSelectionMode = false;
        }

      });

    }
  },
)
                );
              },
            ),
    );
  }
}