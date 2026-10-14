import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../trips/domain/models/stop.dart';
import '../utils/driver_tokens.dart';

class ManageTripStopsScreen extends StatefulWidget {
  final List<Stop>? initialStops;

  const ManageTripStopsScreen({super.key, this.initialStops});

  @override
  State<ManageTripStopsScreen> createState() => _ManageTripStopsScreenState();
}

class _ManageTripStopsScreenState extends State<ManageTripStopsScreen> {
  late List<Stop> _stops;

  @override
  void initState() {
    super.initState();
    _stops = widget.initialStops != null
        ? List<Stop>.from(widget.initialStops!)
        : [];
  }

  void _showStopDialog({Stop? stop, int? index}) {
    final nameCtrl = TextEditingController(text: stop?.name ?? '');
    final notesCtrl = TextEditingController(text: stop?.locationNotes ?? '');
    bool pickup = stop?.pickupAllowed ?? true;
    bool dropoff = stop?.dropoffAllowed ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DriverTokens.radiusCard),
              ),
              title: Text(
                stop == null ? 'إضافة محطة توقف' : 'تعديل المحطة',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم المحطة أو المدينة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: DriverTokens.spaceMd),
                    SwitchListTile(
                      title: const Text(
                        'السماح بصعود الركاب',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
                      ),
                      value: pickup,
                      activeColor: DriverTokens.primaryNavy,
                      onChanged: (val) => setStateDialog(() => pickup = val),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'السماح بنزول الركاب',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
                      ),
                      value: dropoff,
                      activeColor: DriverTokens.primaryNavy,
                      onChanged: (val) => setStateDialog(() => dropoff = val),
                    ),
                    const SizedBox(height: DriverTokens.spaceSm),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات المحطة (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverTokens.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DriverTokens.radiusSmall,
                      ),
                    ),
                  ),
                  onPressed: () {
                    final trimmedName = nameCtrl.text.trim();
                    if (trimmedName.isEmpty) return;

                    final updatedStop = Stop(
                      id:
                          stop?.id ??
                          'stop_${DateTime.now().millisecondsSinceEpoch}',
                      name: trimmedName,
                      pickupAllowed: pickup,
                      dropoffAllowed: dropoff,
                      orderIndex: index ?? _stops.length,
                      locationNotes: notesCtrl.text.trim(),
                    );

                    setState(() {
                      if (index != null) {
                        _stops[index] = updatedStop;
                      } else {
                        _stops.add(updatedStop);
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'حفظ',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Stop item = _stops.removeAt(oldIndex);
      _stops.insert(newIndex, item);

      for (int i = 0; i < _stops.length; i++) {
        _stops[i] = _stops[i].copyWith(orderIndex: i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة محطات التوقف',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          backgroundColor: DriverTokens.primaryNavy,
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () {
                context.pop(_stops);
              },
              child: const Text(
                'تأكيد وحفظ',
                style: TextStyle(
                  color: DriverTokens.accentGold,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: _stops.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.alt_route,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: DriverTokens.spaceMd),
                    const Text(
                      'لم يتم إضافة أي محطات توقف إضافية.',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                    ),
                    const SizedBox(height: DriverTokens.spaceLg),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DriverTokens.primaryNavy,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showStopDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'إضافة محطة الآن',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              )
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(DriverTokens.spaceLg),
                itemCount: _stops.length,
                onReorder: _onReorder,
                itemBuilder: (context, index) {
                  final stop = _stops[index];
                  return Card(
                    key: ValueKey(stop.id),
                    margin: const EdgeInsets.only(bottom: DriverTokens.spaceSm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DriverTokens.radiusSmall,
                      ),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: DriverTokens.primaryNavy.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: DriverTokens.primaryNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        stop.name,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Wrap(
                        spacing: 8,
                        children: [
                          if (stop.pickupAllowed)
                            const Text(
                              '✓ ركوب',
                              style: TextStyle(
                                color: DriverTokens.semanticSuccess,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          if (stop.dropoffAllowed)
                            const Text(
                              '✓ نزول',
                              style: TextStyle(
                                color: DriverTokens.semanticInfo,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          if (stop.locationNotes.isNotEmpty)
                            Text(
                              '(${stop.locationNotes})',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontFamily: 'Cairo',
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: DriverTokens.semanticInfo,
                              size: 20,
                            ),
                            onPressed: () =>
                                _showStopDialog(stop: stop, index: index),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: DriverTokens.semanticError,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _stops.removeAt(index);
                              });
                            },
                          ),
                          const Icon(Icons.drag_handle, color: Colors.grey),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: _stops.isNotEmpty
            ? FloatingActionButton.extended(
                backgroundColor: DriverTokens.primaryNavy,
                foregroundColor: Colors.white,
                onPressed: () => _showStopDialog(),
                icon: const Icon(Icons.add),
                label: const Text(
                  'إضافة محطة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              )
            : null,
      ),
    );
  }
}
